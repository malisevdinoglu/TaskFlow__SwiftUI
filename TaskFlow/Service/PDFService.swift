//
//  PDFService.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 25.10.2025.
//

import Foundation
import SwiftUI // ImageRenderer'ı kullanmak için

class PDFService {
    
    
    @MainActor // UI işlemlerini (ImageRenderer) ana thread'de yapmak için
    func createPDF(from task: LocalAppTask) async -> URL? {
        
       
        let reportView = ReportView(task: task)
        
       
        let renderer = ImageRenderer(content: reportView)
        
     
        // DOĞRU KOD:
        let url = URL.documentsDirectory.appending(path: "TaskFlowRapor-\(task.firebaseId).pdf")
        

        do {
            try await renderer.render { size, context in

                var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                
 
                guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                    return
                }
                
                pdf.beginPDFPage(nil)

                context(pdf)
                
                pdf.endPDFPage()
                pdf.closePDF()
            }
            
            print("PDF başarıyla oluşturuldu ve kaydedildi: \(url.path())")
            // 5. Kaydedilen dosyanın yolunu (URL) döndür
            return url
            
        } catch {
            print("HATA: PDF oluşturulamadı - \(error.localizedDescription)")
            return nil
        }
    }
}
