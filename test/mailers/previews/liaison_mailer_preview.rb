# Preview all emails at http://localhost:3000/rails/mailers/liaison_mailer
class LiaisonMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/liaison_mailer/event_assigned
  def event_assigned
    LiaisonMailer.event_assigned(sample_assignment)
  end

  # Preview this email at http://localhost:3000/rails/mailers/liaison_mailer/event_reminder
  def event_reminder
    LiaisonMailer.event_reminder(sample_assignment)
  end

  private

  # Falls back to building a throwaway assignment (with materials, a
  # drive time, and an office location so every row in the templates has
  # something to render) when the dev database hasn't had one assigned
  # through the UI yet - keeps the preview usable right after db:setup.
  def sample_assignment
    Assignment.includes(:liaison, event: :event_material_items).last || FactoryBot.create(:assignment).tap do |assignment|
      material = FactoryBot.create(:material_item, account: assignment.event.account, name: "A-frame sign")
      FactoryBot.create(:event_material_item, event: assignment.event, material_item: material, quantity: 2)
      assignment.event.update!(drive_distance_meters: 42_000, drive_time_seconds: 2_700)
    end
  end
end
