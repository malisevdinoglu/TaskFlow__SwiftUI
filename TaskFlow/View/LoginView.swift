import SwiftUI
import Combine

struct LoginView: View {
    
    @StateObject private var viewModel = LoginViewModel()
    

    @State private var rememberMe = false
    @State private var isPasswordVisible = false
    
    var body: some View {
        ZStack {
            BackgroundGradient()
            
            VStack {
                Spacer(minLength: 24)
                
                LoginCard {
              
                    LogoHeader()
                    
                    Text("Giriş Yap")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 6)
                        .padding(.bottom, 4)
                    
                    EmailField(text: $viewModel.email)
                    
                    PasswordField(text: $viewModel.password, isVisible: $isPasswordVisible)
                    
                    RememberForgotRow(rememberMe: $rememberMe)
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    PrimaryButton(title: "Giriş Yap") {
                        viewModel.login()
                    }
                    .padding(.top, 6)
                    
                    DividerWithText(text: "veya")
                        .padding(.vertical, 6)
                    
                    SocialButtonsRow()
                        .padding(.top, 2)
                    
                    SignUpRow()
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 24)
            }
        }
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.25), Color.cyan.opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct LoginCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 18) {
            content
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct LogoHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.cyan)
            Text("TaskFlow")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(.top, 6)
    }
}

private struct EmailField: View {
    @Binding var text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "envelope.fill")
                .foregroundColor(.blue.opacity(0.9))
            TextField("E-posta Adresi", text: $text)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .foregroundColor(.white)
                .tint(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct PasswordField: View {
    @Binding var text: String
    @Binding var isVisible: Bool
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .foregroundColor(.blue.opacity(0.9))
            
            Group {
                if isVisible {
                    TextField("Şifre", text: $text)
                } else {
                    SecureField("Şifre", text: $text)
                }
            }
            .foregroundColor(.white)
            .tint(.white)
            
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Şifreyi Göster/Gizle")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct RememberForgotRow: View {
    @Binding var rememberMe: Bool
    var body: some View {
        HStack {
            Toggle(isOn: $rememberMe) {
                Text("Beni Hatırla")
                    .foregroundColor(.white.opacity(0.85))
                    .font(.subheadline)
            }
            .toggleStyle(.checkbox)
            .tint(.blue)
            
            Spacer()
            
            Button(action: {
                // Pasif
            }) {
                Text("Şifremi Unuttum?")
                    .foregroundColor(.white.opacity(0.85))
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }
}

private struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.35), radius: 8, x: 0, y: 6)
        }
    }
}

private struct DividerWithText: View {
    let text: String
    var body: some View {
        HStack {
            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
            Text(text)
                .foregroundColor(.white.opacity(0.7))
                .font(.footnote)
                .padding(.horizontal, 8)
            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
        }
    }
}

private struct SocialButtonsRow: View {
    var body: some View {
        
    }
}

private struct SocialButton: View {
    let title: String
    let systemImage: String
    let iconColor: Color
    var body: some View {
        Button(action: {
       
        }) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundColor(iconColor)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SignUpRow: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Hesabın yok mu?")
                .foregroundColor(.white.opacity(0.8))
            Button(action: {
                
            }) {
                Text("Kaydol")
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.plain)
        }
    }
}


fileprivate struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button {
                configuration.isOn.toggle()
            } label: {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .blue : .white.opacity(0.8))
            }
            .buttonStyle(.plain)
            configuration.label
        }
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var checkbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .preferredColorScheme(.dark)
    }
}
