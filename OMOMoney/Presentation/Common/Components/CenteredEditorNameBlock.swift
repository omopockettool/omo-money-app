import SwiftUI

struct CenteredEditorNameBlock<F: Hashable, Preview: View>: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var maxLength: Int = 30
    let focusedField: FocusState<F?>.Binding
    let fieldValue: F
    let preview: Preview

    init(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        maxLength: Int = 30,
        focusedField: FocusState<F?>.Binding,
        fieldValue: F,
        @ViewBuilder preview: () -> Preview
    ) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.maxLength = maxLength
        self.focusedField = focusedField
        self.fieldValue = fieldValue
        self.preview = preview()
    }

    var body: some View {
        VStack(spacing: 20) {
            preview

            LimitedTextField(
                icon: icon,
                placeholder: placeholder,
                text: $text,
                maxLength: maxLength,
                focusedField: focusedField,
                fieldValue: fieldValue
            )
        }
    }
}
