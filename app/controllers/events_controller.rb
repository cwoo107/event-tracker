class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update candidates auto_assign assign_candidate unassign complete]

  # GET / and GET /map - the main screen: sidebar + map + (optionally) a
  # selected event's detail panel, filtered by the sidebar's search/type form.
  def map
    load_sidebar_events
    @selected_event = Event.includes(detail_includes).find(params[:event_id]) if params[:event_id].present?
  end

  # GET /events/:id - same screen with this event pre-selected. Rendering
  # the :map template (rather than a separate show.html.erb) means direct
  # navigation here gets the full sidebar+map context, while a sidebar row
  # or map marker click (data-turbo-frame="event_detail") only swaps the
  # detail panel, since that's the only part inside that frame.
  def show
    @selected_event = @event
    load_sidebar_events
    render :map
  end

  def new
    @event = Event.new(prep_minutes: 30, teardown_minutes: 30, state: "CA")
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      RefreshDriveTimeJob.perform_later(@event.id)

      if params[:assign_to_me] == "1" && Current.user.liaison
        assignment = @event.assign_to!(Current.user.liaison, by: Current.user, assignment_method: :manual)
        LiaisonMailer.event_assigned(assignment).deliver_later
        redirect_to event_path(@event), notice: "Event created and assigned to you."
      else
        redirect_to event_path(@event), notice: "Event created."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /events/:id/edit - same "replace the card inside the frame" pattern
  # as #candidates, so editing feels like a mode of the detail panel
  # rather than a separate page.
  def edit
    @selected_event = @event
    @editing_event = true
    load_sidebar_events
    render :map
  end

  # Full page redirect on both success and failure (turbo_frame: "_top" on
  # the form - see _edit_form.html.erb) since edited fields like title,
  # date, or location show up in the sidebar rows and map markers too, not
  # just this card.
  def update
    if @event.update(event_params)
      RefreshDriveTimeJob.perform_later(@event.id) if @event.saved_change_to_location?
      sync_material_items!
      redirect_to event_path(@event), notice: "Event updated."
    else
      @selected_event = @event
      @editing_event = true
      load_sidebar_events
      render :map, status: :unprocessable_entity
    end
  end

  # GET /events/:id/candidates - the ranked suggestion list with a score
  # breakdown per criterion (Scoring::Ranking), rendered into the same
  # "event_detail" frame the normal card lives in. Reached from "View
  # ranked suggestions" (unassigned), "Reassign" (assigned, mode=reassign,
  # the default), or "Assign additional liaison" (assigned, mode=add) -
  # excludes whoever's currently assigned from the pool either way, since
  # neither reassigning to nor adding the incumbent makes sense.
  def candidates
    pool = Liaison.active
    pool = pool.where.not(id: @event.liaisons.select(:id)) if @event.liaisons.any?

    @selected_event = @event
    @viewing_candidates = true
    @candidate_mode = params[:mode] == "add" ? "add" : "reassign"
    @ranking = Scoring::Ranking.new(@event, pool: pool)
    @weights = ScoringWeight.current
    load_sidebar_events
    render :map
  end

  # One-click "Auto-assign": takes the top-ranked eligible liaison from the
  # scoring engine, no review step. Redirects with turbo_frame "_top" (see
  # the view) so the whole page - sidebar counts, map marker color, detail
  # panel - reflects the new assignment consistently, not just the frame.
  def auto_assign
    candidate = Scoring::Ranking.new(@event).best

    if candidate
      assignment = @event.assign_to!(candidate.liaison, by: Current.user, assignment_method: :auto,
                                                          score: candidate.score, score_breakdown: candidate.breakdown)
      LiaisonMailer.event_assigned(assignment).deliver_later
      redirect_to event_path(@event)
    else
      redirect_to event_path(@event), alert: "No eligible liaison found for this event."
    end
  end

  # The "manual override" from the ranked list - a coordinator's specific
  # choice, whether or not it's the top-ranked candidate. Re-scores the
  # chosen liaison server-side rather than trusting a client-submitted
  # score, so the stored score_breakdown can't be tampered with.
  # mode=add keeps whoever's already assigned (co-staffing); anything else
  # replaces them, matching the "Reassign" link's behavior.
  def assign_candidate
    liaison = Liaison.find(params[:liaison_id])
    candidate = Scoring::Ranking.new(@event, pool: Liaison.where(id: liaison.id)).candidates.first

    assignment =
      if params[:mode] == "add" || @event.liaisons.empty?
        @event.assign_to!(liaison, by: Current.user, assignment_method: :manual,
                                    score: candidate&.score, score_breakdown: candidate&.breakdown || {})
      else
        @event.reassign_to!(liaison, by: Current.user, assignment_method: :manual,
                                      score: candidate&.score, score_breakdown: candidate&.breakdown || {})
      end
    LiaisonMailer.event_assigned(assignment).deliver_later

    redirect_to event_path(@event)
  end

  def unassign
    @event.unassign!(by: Current.user)
    redirect_to event_path(@event)
  end

  def complete
    @event.complete!(by: Current.user)
    redirect_to event_path(@event)
  end

  private

  def set_event
    @event = Event.includes(detail_includes).find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :title, :event_type, :estimated_attendees, :audience,
      :starts_at, :ends_at, :prep_minutes, :teardown_minutes,
      :address, :venue_name, :city, :county, :state, :zip, :latitude, :longitude,
      :requester_organization, :requester_name, :requester_email, :requester_phone,
      :overnight_approved
    )
  end

  # Materials aren't a Rails nested-attributes association here on purpose -
  # the catalog is a small, fixed list rendered as one checkbox + quantity
  # per MaterialItem regardless of whether this event already has a row for
  # it, so there's no stable "existing record index" for nested_attributes
  # to key off. Checked -> create/update the join row; unchecked -> remove
  # it, since that means "wasn't handed out" rather than "handed out zero."
  def sync_material_items!
    (params[:materials] || {}).each do |material_item_id, attrs|
      material = MaterialItem.find_by(id: material_item_id)
      next unless material

      if ActiveModel::Type::Boolean.new.cast(attrs[:checked])
        item = @event.event_material_items.find_or_initialize_by(material_item: material)
        item.quantity = attrs[:quantity].presence&.to_i || 1
        item.checked = true
        item.checked_by = Current.user
        item.checked_at ||= Time.current
        item.save!
      else
        @event.event_material_items.where(material_item: material).destroy_all
      end
    end
  end

  def load_sidebar_events
    scope = Event.includes(:liaisons)
    scope = scope.where(event_type: params[:type]) if params[:type].present? && params[:type] != "all"
    if params[:q].present?
      scope = scope.where("title ILIKE :q OR city ILIKE :q OR county ILIKE :q", q: "%#{params[:q]}%")
    end

    @unassigned_events = scope.unassigned.order(:starts_at)
    @assigned_events = scope.assigned.order(:starts_at)
    @completed_events = scope.completed.order(starts_at: :desc)
    @liaisons = Liaison.active.includes(:user).order(:region)
  end

  def detail_includes
    [:liaisons, { event_material_items: :material_item }, { notes: :author }, { activities: :actor }]
  end
end
