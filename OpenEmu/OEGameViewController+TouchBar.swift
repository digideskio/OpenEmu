/*
 Copyright (c) 2016, OpenEmu Team
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the OpenEmu Team nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Cocoa

@available(OSX 10.12.1, *)
fileprivate enum GameplaySegments: Int {
    case pauseGameplay = 0
    case restartSystem = 1
}

@available(OSX 10.12.1, *)
fileprivate enum SaveStatesSegments: Int {
    case quickSave = 0
    case quickLoad = 1
}

@available(OSX 10.12.1, *)
fileprivate enum VolumeSegments: Int {
    case down = 0
    case up   = 1
}

@available(OSX 10.12.1, *)
fileprivate extension NSTouchBarCustomizationIdentifier {
    static let touchBar = NSTouchBarCustomizationIdentifier("org.openemu.GameViewControllerTouchBar")
}

@available(OSX 10.12.1, *)
fileprivate extension NSTouchBarItemIdentifier {
    static let stop = NSTouchBarItemIdentifier("org.openemu.GameViewControllerTouchBar.stop")
    static let gameplay = NSTouchBarItemIdentifier("org.openemu.GameViewControllerTouchBar.gameplay")
    static let saveStates = NSTouchBarItemIdentifier("saveStateControls")
    static let volume = NSTouchBarItemIdentifier("org.openemu.GameViewControllerTouchBar.volume")
    static let toggleFullScreen = NSTouchBarItemIdentifier("org.openemu.GameViewControllerTouchBar.toggleFullScreen")
}

@available(OSX 10.12.1, *)
extension OEGameViewController {
    
    open override func makeTouchBar() -> NSTouchBar? {
        
        let touchBar = NSTouchBar()
        
        touchBar.delegate = self
        touchBar.customizationIdentifier = .touchBar
        touchBar.defaultItemIdentifiers = [.stop,
                                           .gameplay,
                                           .saveStates,
                                           .volume,
                                           .toggleFullScreen,
                                           .otherItemsProxy]
        touchBar.customizationAllowedItemIdentifiers = [.stop,
                                                        .gameplay,
                                                        .saveStates,
                                                        .volume,
                                                        .toggleFullScreen]
        
        return touchBar
    }
}

@available(OSX 10.12.1, *)
extension OEGameViewController: NSTouchBarDelegate {
    
    public func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        
        switch identifier {
            
        case NSTouchBarItemIdentifier.stop:
            
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.customizationLabel = NSLocalizedString("Stop Emulation", comment: "")
            
            let button = NSButton(image: NSImage(named: NSImageNameTouchBarRecordStopTemplate)!, target: nil, action: #selector(OEGameDocument.stopEmulation(_:)))
            
            button.bezelColor = #colorLiteral(red: 0.5665243268, green: 0.2167189717, blue: 0.2198875844, alpha: 1)
            
            item.view = button
            
            return item
            
        case NSTouchBarItemIdentifier.gameplay:
            
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.customizationLabel = NSLocalizedString("Pause & Reset", comment: "")
            
            let segmentImages = [NSImageNameTouchBarPauseTemplate,
                                 NSImageNameTouchBarRefreshTemplate]
                                .map { NSImage(named: $0)! }
            
            let segmentedControl = NSSegmentedControl(images: segmentImages, trackingMode: .momentary, target: nil, action: #selector(OEGameViewController.gameplayControlsTouched(_:)))
            
            segmentedControl.segmentStyle = .separated
            
            item.view = segmentedControl
            
            return item
            
        case NSTouchBarItemIdentifier.saveStates:

            guard supportsSaveStates else {
                return nil
            }
            
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.customizationLabel = NSLocalizedString("Save States", comment: "")
            
            let segmentImages = [#imageLiteral(resourceName: "quick_save_touch_bar_template"),
                                 #imageLiteral(resourceName: "quick_load_touch_bar_template")]
            
            let segmentedControl = NSSegmentedControl(images: segmentImages, trackingMode: .momentary, target: nil, action: #selector(OEGameViewController.saveStatesControlsTouched(_:)))
            
            segmentedControl.segmentStyle = .separated
            
            item.view = segmentedControl
            
            return item
            
        case NSTouchBarItemIdentifier.volume:
            
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.customizationLabel = NSLocalizedString("Volume", comment: "")
            
            let segmentImages = [NSImageNameTouchBarVolumeDownTemplate,
                                 NSImageNameTouchBarVolumeUpTemplate]
                                .map { NSImage(named: $0)! }
            
            let segmentedControl = NSSegmentedControl(images: segmentImages, trackingMode: .momentary, target: nil, action: #selector(OEGameViewController.volumeTouched(_:)))
            
            segmentedControl.segmentStyle = .separated
            
            let volume = document.volume
            
            segmentedControl.setEnabled(volume > 0, forSegment: VolumeSegments.down.rawValue)
            segmentedControl.setEnabled(volume < 1, forSegment: VolumeSegments.up.rawValue)
            
            item.view = segmentedControl
                        
            return item
            
        case NSTouchBarItemIdentifier.toggleFullScreen:
            
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.customizationLabel = NSLocalizedString("Toggle Full Screen", comment: "")
            
            let imageName = document.gameWindowController.window!.isFullScreen ? NSImageNameTouchBarExitFullScreenTemplate : NSImageNameTouchBarEnterFullScreenTemplate
            let image = NSImage(named: imageName)!
            let button = NSButton(image: image, target: nil, action: #selector(OEGameViewController.toggleFullScreen(_:)))
            
            item.view = button
            
            return item
            
        default:
            return nil
        }
    }
    
    @objc private func gameplayControlsTouched(_ sender: Any?) {
        
        guard let segmentedControl = sender as? NSSegmentedControl else {
            return
        }
        
        // Force-unwrap so that unhandled segments are noticed immediately.
        switch GameplaySegments(rawValue: segmentedControl.selectedSegment)! {
            
        case .pauseGameplay:
            
            document.toggleEmulationPaused(self)
            
            let imageName = document.isEmulationPaused ? NSImageNameTouchBarPlayTemplate : NSImageNameTouchBarPauseTemplate
            segmentedControl.setImage(NSImage(named: imageName)!, forSegment: 0)
            
        case .restartSystem:
            document.resetEmulation(self)
        }
    }
    
    @objc private func saveStatesControlsTouched(_ sender: Any?) {
        
        guard let segmentedControl = sender as? NSSegmentedControl else {
            return
        }
        
        // Force-unwrap so that unhandled segments are noticed immediately.
        switch SaveStatesSegments(rawValue: segmentedControl.selectedSegment)! {
            
        case .quickSave:
            document.quickSave(self)
            
        case .quickLoad:
            document.quickLoad(self)
        }
    }
    
    @objc private func volumeTouched(_ sender: Any?) {
        
        guard let segmentedControl = sender as? NSSegmentedControl else {
            return
        }
        
        // Force-unwrap so that unhandled segments are noticed immediately.
        switch VolumeSegments(rawValue: segmentedControl.selectedSegment)! {
            
        case .down:
            document.volumeDown(self)
            
        case .up:
            document.volumeUp(self)
        }
        
        let volume = document.volume
        
        segmentedControl.setEnabled(volume > 0, forSegment: VolumeSegments.down.rawValue)
        segmentedControl.setEnabled(volume < 1, forSegment: VolumeSegments.up.rawValue)
    }
    
    @objc private func toggleFullScreen(_ sender: Any?) {
        
        document.toggleFullScreen(self)
        
        let item = touchBar!.item(forIdentifier: .toggleFullScreen)!
        let button = item.view! as! NSButton
        
        let imageName = document.gameWindowController.window!.isFullScreen ? NSImageNameTouchBarExitFullScreenTemplate : NSImageNameTouchBarEnterFullScreenTemplate
        button.image = NSImage(named: imageName)!
    }
}
