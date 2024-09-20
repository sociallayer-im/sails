module Components::RowEventHelper
    def row_event(eventid=nil, **options, &block)
      options[:class] = tw("border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted", options[:class])
      content = capture(&block) if block
      render partial: "dashboard/components/row_event", locals:{options: options, eventid: eventid, content: content}
    end
  end