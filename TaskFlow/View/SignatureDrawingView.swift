import SwiftUI

// ... (Line struct'ı GÜNCELLENDİ) ...
struct Line {
    var points: [CGPoint] = []
    
    // 'Color.black' -> 'Color(uiColor: .black)' olarak değişti
    // 'uiColor: .black' her zaman siyahtır, Koyu Mod'dan etkilenmez.
    var color: Color = Color(uiColor: .black)
    
    var lineWidth: CGFloat = 3.0
}

struct SignatureDrawingView: View {
    
    // ... (State değişkenleri, onSave, dismiss aynı kaldı) ...
    @State private var lines: [Line] = []
    @State private var currentLine = Line()
    var onSave: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    
    
    // ... (drawingCanvas GÜNCELLENDİ) ...
    var drawingCanvas: some View {
        Canvas { context, size in
            // ... (çizim kodu aynı kaldı) ...
            for line in lines {
                var path = Path()
                path.addLines(line.points)
                context.stroke(path, with: .color(line.color), lineWidth: line.lineWidth)
            }
            var currentPath = Path()
            currentPath.addLines(currentLine.points)
            context.stroke(currentPath, with: .color(currentLine.color), lineWidth: currentLine.lineWidth)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        
        // '.background(Color.white)' -> '.background(Color(uiColor: .white))' olarak değişti
        // 'uiColor: .white' her zaman beyazdır, Koyu Mod'dan etkilenmez.
        .background(Color(uiColor: .white))
        
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray))
    }
    

    var body: some View {
        VStack {
            Text("Lütfen Müşteri İmzasını Alın")
                .font(.title3.bold())
                .padding()

            drawingCanvas
                .gesture(
                    // ... (gesture kodu aynı kaldı) ...
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            currentLine.points.append(value.location)
                        }
                        .onEnded { value in
                            lines.append(currentLine)
                            currentLine = Line()
                        }
                )
            
            // ... (HStack ve Butonlar aynı kaldı) ...
            HStack(spacing: 20) {
                Button(action: {
                    lines.removeAll()
                    currentLine = Line()
                }) {
                    Label("Temizle", systemImage: "trash")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // 1) Render edilecek alanın boyutunu hesapla
                    // drawingCanvas minHeight: 300; genişlik cihaz genişliği kadar. Güvenli bir sabit boyut kullanalım.
                    let targetWidth: CGFloat = UIScreen.main.bounds.width - 32 // padding düşülmüş yaklaşık genişlik
                    let targetHeight: CGFloat = 300
                    
                    let format = UIGraphicsImageRendererFormat.default()
                    format.scale = 2.0
                    format.opaque = true // ARKA PLAN OPAK
                    
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: targetWidth, height: targetHeight), format: format)
                    
                    let image = renderer.image { ctx in
                        // 2) Beyaz arka planı doldur
                        UIColor.white.setFill()
                        ctx.fill(CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
                        
                        // 3) Çizgileri CoreGraphics ile çiz
                        let cgContext = ctx.cgContext
                        cgContext.setLineCap(.round)
                        
                        // Kaydedilmiş çizgiler
                        for line in lines {
                            cgContext.setStrokeColor(UIColor.black.cgColor)
                            cgContext.setLineWidth(line.lineWidth)
                            guard line.points.count > 1 else { continue }
                            cgContext.beginPath()
                            cgContext.addLines(between: line.points)
                            cgContext.strokePath()
                        }
                        
                        // Devam eden çizgi
                        if currentLine.points.count > 1 {
                            cgContext.setStrokeColor(UIColor.black.cgColor)
                            cgContext.setLineWidth(currentLine.lineWidth)
                            cgContext.beginPath()
                            cgContext.addLines(between: currentLine.points)
                            cgContext.strokePath()
                        }
                    }
                    
                    if let data = image.pngData() {
                        onSave(data)
                    }
                    dismiss()
                }) {
                    Label("Kaydet", systemImage: "checkmark.circle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        // Arka planın Koyu Mod'dan etkilenmemesi için '.black' yerine
        // semantik olmayan bir renk kullanıyoruz
        .background(Color(uiColor: .systemGray6))
    }
}

// ... (Önizleme aynı kaldı) ...
struct SignatureDrawingView_Previews: PreviewProvider {
    static var previews: some View {
        SignatureDrawingView(onSave: { _ in })
    }
}
