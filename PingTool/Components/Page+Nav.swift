import SwiftUI

// 定义扩展
extension View {
    func removeBar() -> some View {
        self.modifier(CustomBackButtonModifier())
    }
}

struct CustomBackButtonModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    func body(content: Content) -> some View {
        content
#if os(iOS)
           .navigationBarBackButtonHidden(true)
           .navigationBarItems(trailing: closeButton)
           #else
           .toolbar {
               ToolbarItem(placement: .navigation) {
                   closeButton
               }
           }
           #endif
    }
    
    private var closeButton: some View {
         Button(action: {
             dismiss()
         }) {
             Image(systemName: "xmark.circle")
                 .font(.system(size: 16, weight: .medium))
                 .foregroundColor(ThemeColors.textPrimary)
         }
         #if os(macOS)
         .buttonStyle(.borderless)
         .help("关闭")
         #endif
     }
}
