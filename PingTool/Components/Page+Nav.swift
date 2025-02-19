import SwiftUI

// 定义扩展
extension View {
    func removeBar() -> some View {
        self.modifier(CustomBackButtonModifier())
    }
}

struct CustomBackButtonModifier: ViewModifier {
    @Environment(\.presentationMode) var presentationMode
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true) // 隐藏系统返回按钮
            .navigationBarItems(leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss() // 触发返回
            }) {
                HStack {
                    Image(systemName: "chevron.left") // 自定义箭头
                        .foregroundColor(.black)
                }
            })
    }
}
