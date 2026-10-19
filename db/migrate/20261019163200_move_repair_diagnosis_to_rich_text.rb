# The diagnosis becomes rich text, stored by Action Text in action_text_rich_texts.
# The plain text already written is escaped (it was never HTML) and copied over
# row by row before the old column goes away.
class MoveRepairDiagnosisToRichText < ActiveRecord::Migration[8.1]
  class RichText < ActiveRecord::Base
    self.table_name = "action_text_rich_texts"
  end

  def up
    select_rows("SELECT id, diagnosis FROM repairs WHERE diagnosis IS NOT NULL AND diagnosis <> ''").each do |id, text|
      body = ERB::Util.html_escape(text).gsub(/\r?\n/, "<br>")
      RichText.create!(record_type: "Repair", record_id: id, name: "diagnosis", body: "<div>#{body}</div>")
    end

    remove_column :repairs, :diagnosis
  end

  def down
    add_column :repairs, :diagnosis, :text

    RichText.where(record_type: "Repair", name: "diagnosis").find_each do |rich_text|
      text = ActionText::Content.new(rich_text.body).to_plain_text
      execute "UPDATE repairs SET diagnosis = #{connection.quote(text)} WHERE id = #{rich_text.record_id.to_i}"
      rich_text.delete
    end
  end
end
