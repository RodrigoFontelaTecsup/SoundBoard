//
//  SoundViewController.swift
//  FontelaSoundBoard
//
//  Created by Rodrigo Fontela on 10/29/23.
//  Copyright © 2023 Rodrigo Fontela. All rights reserved.
//

import UIKit
import AVFoundation

class SoundViewController: UIViewController {
    
    // Conexiones Outlet
    @IBOutlet weak var grabarButton: UIButton!
    @IBOutlet weak var reproducirButton: UIButton!
    @IBOutlet weak var nombreTextField: UITextField!
    @IBOutlet weak var agregarButton: UIButton!
    @IBOutlet weak var tiempoLabel: UILabel!
    
    
    var grabarAudio:AVAudioRecorder?
    var reproducirAudio:AVAudioPlayer?
    var audioURL:URL?
    var tiempoGrabacion: TimeInterval = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        configurarGrabacion()
        reproducirButton.isEnabled = false
        agregarButton.isEnabled = false
    }
    
    // Funcion para actualizar el tiempo
    func actualizarTiempoLabel() {
        let minutos = Int(tiempoGrabacion) / 60
        let segundos = Int(tiempoGrabacion) % 60
        tiempoLabel.text = String(format: "%02d:%02d", minutos, segundos)
    }

    func configurarGrabacion() {
        do {
            // creando sesion de auido
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: [])
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true)
            
            // creacion direccion para el archivo de audio
            let basePath:String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let pathComponents = [basePath, "audio.m4a"]
            audioURL = NSURL.fileURL(withPathComponents: pathComponents)!
            
            // impresion de ruta donde se guardar los archivos
            print("************************")
            print(audioURL!)
            print("************************")
            
            // crear opciones para el grabador de audio
            var settings:[String:AnyObject] = [:]
            settings[AVFormatIDKey] = Int(kAudioFormatMPEG4AAC) as AnyObject?
            settings[AVSampleRateKey] = 44100.0 as AnyObject?
            settings[AVNumberOfChannelsKey] = 2 as AnyObject?
            
            // crear el objeto de grabacion de audio
            grabarAudio = try AVAudioRecorder(url: audioURL!, settings: settings)
            grabarAudio!.prepareToRecord()
        } catch let error as NSError {
            print(error)
        }
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, let grabarAudio = self.grabarAudio else { return }
            if grabarAudio.isRecording {
                self.tiempoGrabacion += 1
                self.actualizarTiempoLabel()
            }
        }
    }
    
    // Conexiones Action
    @IBAction func grabarTapped(_ sender: Any) {
        if grabarAudio!.isRecording {
            // detener la grabacion
            grabarAudio?.stop()
            // cambiar el texto del boton grabar
            grabarButton.setTitle("GRABAR", for: .normal)
            reproducirButton.isEnabled = true
            agregarButton.isEnabled = true
        } else {
            // empezar a grabar
            grabarAudio?.record()
            // cambiar el texto del boton grabar a detener
            grabarButton.setTitle("DETENER", for: .normal)
            reproducirButton.isEnabled = false
        }
    }
    
    @IBAction func reproducirTapped(_ sender: Any) {
        do {
            try reproducirAudio = AVAudioPlayer(contentsOf: audioURL!)
            reproducirAudio!.play()
            print("Reproduciendo")
        } catch{}
    }
    
    @IBAction func agregarTapped(_ sender: Any) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let grabacion = Grabacion(context: context)
        grabacion.nombre = nombreTextField.text
        grabacion.audio = NSData(contentsOf: audioURL!)! as Data
        grabacion.tiempoDuracion = tiempoGrabacion
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        navigationController!.popViewController(animated: true)
    }
    
    // Funcion controlar volumen
    @IBAction func ajustarVolumen(_ sender: UISlider) {
        let nuevoVolumen = sender.value
        reproducirAudio?.volume = nuevoVolumen
    }
    
}
