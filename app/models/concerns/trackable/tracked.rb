module Trackable::Tracked
  extend ActiveSupport::Concern

  included do
    field :tracked_day, type: Integer
    field :tracked_weekday, type: Integer
    field :tracked_hour, type: Integer
    field :tracked_minute, type: Integer

    index({
      tracked_day: 1,
    }, {
      background: true
    })

    index({
      tracked_weekday: 1,
    }, {
      background: true
    })

    index({
      tracked_hour: 1,
    }, {
      background: true
    })

    index({
      tracked_minute: 1,
    }, {
      background: true
    })

    before_save :assign_track_time
  end

  private
  def assign_track_time
    tracked_at = self.created_at || DateTime.now

    self.tracked_day = tracked_at.day
    self.tracked_weekday = tracked_at.wday
    self.tracked_hour = tracked_at.hour
    self.tracked_month = tracked_at.month
  end
end
