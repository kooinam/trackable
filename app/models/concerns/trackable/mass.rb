module Trackable::Mass
  extend ActiveSupport::Concern

  class_methods do
    def trackable_export(&block)
      define_singleton_method('export') do |user_email, ids|
        items = where(:id.in => ids).order(created_at: :asc)

        params = block.call(items)

        MassMailer.export(user_email, params).deliver
      end
    end

    def trackable_import(&block)
      define_singleton_method('import') do |user_email, owner, attachment_id|
        if owner
          owner.reload
        end

        attachment = Attachment.find(attachment_id)
        faulty = nil
        params = {}

        begin
          xlsx = nil

          Dir.mkdir('tmp/spreadsheets') unless File.exists?('tmp/spreadsheets')
          file_name = "tmp/spreadsheets/#{attachment[:content]}"

          open(file_name, 'wb') do |file|
            file << attachment.content.read
          end

          xlsx = Roo::Spreadsheet.open(file_name)

          File.delete(file_name)

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

              if block.call(index, item, user_email, owner)
                params[sheet] += 1
              end
            end
          end

          # Trackable::Activity.track('import_records', extras: {
          #   attachment_id: attachment_id,
          #   records: self.name.humanize,
          # }, recipients: recipients)

          MassMailer.import(true, user_email, params).deliver
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

          pp '---'
          pp e
          pp e.backtrace
          pp '---'

          MassMailer.import(false, user_email, params).deliver
        end
      end
    end
  end
end
