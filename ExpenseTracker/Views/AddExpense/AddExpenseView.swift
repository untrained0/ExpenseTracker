import SwiftUI

/// The keypad-first entry screen. This is where the Action Button lands.
///
/// **Focus model:** the amount is the active field the moment the sheet appears, with
/// the caret blinking and the keypad ready, so no tap is needed first. Editing the note
/// moves focus to a system `TextField` and hides the keypad. Tapping the amount, or
/// pressing Return, gives focus back.
struct AddExpenseView: View {
    @State private var viewModel: AddExpenseViewModel
    @FocusState private var isNoteFocused: Bool
    @State private var keyPressCount = 0

    @Environment(\.dismiss) private var dismiss

    init(viewModel: AddExpenseViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var isAmountFocused: Bool { !isNoteFocused }

    var body: some View {
        VStack(spacing: 16) {
            header

            Spacer(minLength: 0)

            AmountDisplayView(
                text: viewModel.amountText,
                currencySymbol: AppCurrency.symbol,
                isPlaceholder: viewModel.amountInput.isEmpty,
                isFocused: isAmountFocused,
                tint: viewModel.category.tint
            )
            .contentShape(Rectangle())
            .onTapGesture { isNoteFocused = false }

            noteField

            Spacer(minLength: 0)

            CategoryPickerView(selection: $viewModel.category)

            if isAmountFocused {
                KeypadView(
                    onKey: { key in
                        viewModel.press(key)
                        keyPressCount += 1
                    },
                    onClear: {
                        viewModel.clearAmount()
                        keyPressCount += 1
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            saveButton
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .animation(.snappy, value: isNoteFocused)
        .sensoryFeedback(.impact(weight: .light), trigger: keyPressCount)
        // Once an amount is typed, a stray swipe-down shouldn't throw it away. ✕ still works.
        .interactiveDismissDisabled(!viewModel.amountInput.isEmpty)
        .presentationDragIndicator(.visible)
        .alert(
            "Couldn't save",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(.fill.tertiary, in: Circle())
            }
            .accessibilityLabel("Cancel")

            Spacer()

            DatePicker(
                "Date",
                selection: $viewModel.date,
                in: ...Date.now,
                displayedComponents: .date
            )
            .labelsHidden()
        }
        .overlay {
            Text("New Expense")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, 20)
    }

    private var noteField: some View {
        HStack(spacing: 8) {
            Image(systemName: "text.bubble")
                .foregroundStyle(.secondary)
            TextField("Add a note", text: $viewModel.note)
                .focused($isNoteFocused)
                .submitLabel(.done)
                .onSubmit { isNoteFocused = false }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.fill.tertiary, in: Capsule())
        .padding(.horizontal, 40)
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(viewModel.saveButtonTitle)
                .font(.headline)
                .monospacedDigit()
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(viewModel.category.tint)
        .disabled(!viewModel.canSave)
        .padding(.horizontal, 20)
    }

    private func save() {
        guard viewModel.save() else { return }
        Haptics.success()
        dismiss()
    }
}

#if DEBUG
#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        AddExpenseView(viewModel: AddExpenseViewModel(repository: PreviewData.repository))
    }
}
#endif
