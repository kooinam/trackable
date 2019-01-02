module Trackable::Mass
  extend ActiveSupport::Concern

  class_methods do
    def trackable_export(&block)
      define_singleton_method('export') do |user, ids|
        items = where(:id.in => ids).order(created_at: :asc)

        params = block.call(items)

        MassMailer.export(user, params).deliver
      end
    end

    def trackable_import(&block)
      define_singleton_method('import') do |user, ids, attachment_id, owner, recipients = [], force_create = false, file_name = nil|
        user.reload

        if owner
          owner.reload
        end

        attachment = user.attachments.find_by_id(attachment_id)
        faulty = nil
        params = {}

        begin
          xlsx = nil

          if file_name.nil? # import by
            Dir.mkdir('tmp/spreadsheets') unless File.exists?('tmp/spreadsheets')
            file_name = "tmp/spreadsheets/#{attachment[:content]}"
            open(file_name, 'wb') do |file|
              file << attachment.content.read
            end
            xlsx = Roo::Spreadsheet.open(file_name)
            File.delete(file_name)
          else # import from console
            xlsx = Roo::Spreadsheet.open(file_name)
          end

          xlsx.sheets.each_with_index do |sheet, index|
            rows = xlsx.sheet(sheet).to_a
            attribute_names = rows[0].to_a

            params[sheet] = 0

            rows[1..-1].each do |row|
              item = {}
              attribute_names.each_with_index do |attribute_name, index|
                item[attribute_name.split(' ').join('_').underscore] = row[index]
              end

              faulty = item

              if block.call(index, item, ids, owner, user)
                params[sheet] += 1
              end
            end
          end

          # Trackable::Activity.track('import_records', extras: {
          #   attachment_id: attachment_id,
          #   records: self.name.humanize,
          # }, recipients: recipients)

          MassMailer.import(true, user, params).deliver
        rescue Exception => e
          # Trackable::Activity.track('import_records_error', extras: {
          #   attachment_id: attachment_id,
          #   records: self.name.humanize,
          #   error: e.message,
          #   backtrace: e.backtrace,
          #   faulty: faulty,
          #   key: 'records',
          #   value: self.name.humanize,
          # }, recipients: recipients)

          MassMailer.import(false, user, params).deliver
        end
      end
    end
  end
end
