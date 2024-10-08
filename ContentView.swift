//
//  ContentView.swift
//  SleepSounds
//
//  Created by Kevin Wong on 10/7/24.
//

import CoreML
import SwiftUI
import AVKit

class SoundManager {
    
    static let instance = SoundManager()
    
    var player: AVAudioPlayer?
    
    enum SoundOption: String, CaseIterable {
        case serene = "serene-harmony"
        case rain = "rain"
        case ocean = "ocean-waves"
    }
    
    func playSound(sound: SoundOption, loop: Bool = true) {
        stopSound()
        
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else { return }
        print("Playing sound from URL: \(url)")
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loop ? -1 : 0
            player?.play()
            print("\(sound.rawValue) playing")
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stopSound() {
        player?.stop()
        player = nil
    }
    
}


struct ContentView: View {
    
    @State private var wakeUp = defaultWakeTime
    @State private var sleepAmount = 8.0
    @State private var coffeeAmount = 1
    
    @State private var selectedSound: SoundManager.SoundOption = .serene
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
     
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
    var body: some View {
        NavigationStack {
            Form {
                VStack(alignment: .leading,spacing: 0) {
                    Text("When do you want to wake up").font(.headline)
                    
                    DatePicker("Please enter a time", selection: $wakeUp, displayedComponents: [.hourAndMinute]).labelsHidden()
                }
                
                VStack(alignment: .leading,spacing: 0) {
                    Text("Desired amount of sleep").font(.headline)
                    
                    Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.5)
                }
                
                VStack(alignment: .leading,spacing: 0) {
                    Text("Daily coffee intake").font(.headline)
                    
                    Stepper(coffeeAmount == 1 ? "1 cup" : "\(coffeeAmount) cups", value: $coffeeAmount, in: 1...20)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Select sleep sound").font(.headline)
                    
                    Picker("Sleep Sound", selection: $selectedSound) {
                        ForEach(SoundManager.SoundOption.allCases, id: \.self) { sound in
                            Text(sound.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()).labelsHidden().padding()
                }
                 
                Button("Play sleep sound") {
                    SoundManager.instance.playSound(sound: selectedSound)
                }
                Button("Stop sleep sound") {
                    SoundManager.instance.stopSound()

                }
            }
            .navigationTitle("Sleep Sounds")
            .toolbar {
                Button("Calculate", action: calcBedTime)
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
        
    }
    
    func calcBedTime() {
        // CoreML can throw errors
        do {
            let config = MLModelConfiguration()
            let model = try SleepCalc(configuration: config)
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = ( components.hour ?? 0 ) * 60 * 60
            let minute = ( components.minute ?? 0) * 60
            
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))
            
            let sleepTime = wakeUp - prediction.actualSleep
            alertTitle = "Your ideal bedtime is..."
            alertMessage = sleepTime.formatted(date: .omitted, time: .shortened)
            
        } catch {
            alertTitle = "error"
            alertMessage = "sorry, there was a problem calculating bedtime"
        }
        showingAlert = true
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
