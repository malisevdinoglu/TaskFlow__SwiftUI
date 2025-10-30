//
//  SettingsView.swift
//  Created by Mehmet Ali Sevdinoğlu on 25.10.2025.

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var selectedTheme = 0
    @State private var showSignOutAlert = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.25), Color.cyan.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .opacity(0)
                            .frame(width: 24)
                        Spacer()
                        VStack(spacing: 4) {
                            Text("Ayarlar")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                            Text("Uygulama tercihlerini düzenleyin")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "gearshape.fill")
                            .opacity(0)
                            .frame(width: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
         
                    SettingsCardContainer {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Görünüm", systemImage: "paintbrush.pointed.fill")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Tema")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Picker("Tema", selection: $selectedTheme) {
                                    Text("Sistem").tag(0)
                                    Text("Açık").tag(1)
                                    Text("Koyu").tag(2)
                                }
                                .pickerStyle(.segmented)
                                .colorScheme(.dark)
                                
                                Text("Uygulamanın görünüm temasını seçin.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Hesap Kartı
                    SettingsCardContainer {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Hesap", systemImage: "person.crop.circle.fill")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                SettingRow(icon: "envelope.fill",
                                           title: "E-posta",
                                           value: authViewModel.authUser?.email ?? "—")
                                
                                SettingRow(icon: "person.text.rectangle",
                                           title: "Rol",
                                           value: authViewModel.currentUser?.role ?? "—")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                
                    SettingsCardContainer {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Destek ve Hakkında", systemImage: "questionmark.circle.fill")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            VStack(spacing: 10) {
                                SecondaryButton(title: "SSS / Yardım", systemImage: "book.fill") {
                              
                                }
                                SecondaryButton(title: "Geri Bildirim Gönder", systemImage: "paperplane.fill") {
                                   
                                }
                                SecondaryButton(title: "Hakkında", systemImage: "info.circle.fill") {
                                  
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
           
                    Button(action: {
                        showSignOutAlert = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
                            Text("Çıkış Yap")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule().fill(Color.red)
                        )
                        .shadow(color: Color.red.opacity(0.35), radius: 10, x: 0, y: 6)
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 10)
                    .alert("Çıkış yapmak istediğinize emin misiniz?", isPresented: $showSignOutAlert) {
                        Button("İptal", role: .cancel) {}
                        Button("Evet", role: .destructive) {
                            authViewModel.signOut()
                        }
                    }
                    
                    Spacer(minLength: 16)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct SettingsCardContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct SettingRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private struct SecondaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundColor(.white)
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Önizleme

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(AuthViewModel())
        }
        .preferredColorScheme(.dark)
    }
}
