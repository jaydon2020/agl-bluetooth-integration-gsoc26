# Bluetooth Sequence Diagrams (Detailed with Activations, D-Bus Objects, & Block Logic)

## 1. Bluetooth On/Off
```mermaid
sequenceDiagram
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant A as Adapter1 (bluez)
    participant R as rfkill

    activate BN
    alt User Toggle Off
        UI->>BN: setPowered(false)
        BN->>A: SetProperty("Powered", false)
        activate A
        A-->>BN: Success / adapterChanged
        deactivate A
        BN-->>UI: Update UI (Bluetooth Off)
    else User Toggle On (Success)
        UI->>BN: setPowered(true)
        BN->>A: SetProperty("Powered", true)
        activate A
        A-->>BN: Success / adapterChanged
        deactivate A
        BN-->>UI: Update UI (Bluetooth On)
    else User Toggle On (Currently Blocked by rfkill)
        UI->>BN: setPowered(true)
        BN->>R: unblock (rfkill)
        activate R
        R-->>BN: Success
        deactivate R
        BN->>A: SetProperty("Powered", true)
        activate A
        A-->>BN: Success / adapterChanged
        deactivate A
        BN-->>UI: Update UI (Bluetooth On)
    end
    deactivate BN
```

## 2. Pairing
```mermaid
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant A as Adapter1 (bluez)
    participant D as Device1 (bluez)
    participant O as Other Devices (bluez)
    participant AM as AgentManager1 (bluez)

    UI->>BN: enterScanMode()
    activate BN
    BN->>A: SetDiscoveryFilter(uuids: A2DP, AVRCP, HFP)
    activate A
    A-->>BN: Success
    deactivate A
    BN->>A: StartDiscovery()
    activate A
    A-->>BN: Success
    deactivate A
    BN-->>UI: Scan Started
    deactivate BN

    A->>BN: deviceAdded (Device1 Object)
    activate BN
    BN-->>UI: Update UI (Discovered Devices)
    deactivate BN
    
    UI->>BN: pairAndConnect(Mobile)
    activate BN
    BN->>D: SetProperty("Blocked", false)
    activate D
    D-->>BN: Success
    deactivate D
    
    opt If not trusted
        BN->>D: SetProperty("Trusted", true)
        activate D
        D-->>BN: Success
        deactivate D
    end
    
    BN->>D: Pair()
    activate D
    D->>M: Bluetooth Pairing Protocol
    activate M
    M-->>D: Protocol Response
    deactivate M
    
    D->>AM: RequestConfirmation / AuthorizeService
    activate AM
    AM->>BN: agentRequest
    activate BN
    BN->>UI: showPairingDialog()
    activate UI
    UI-->>BN: User clicks Accept
    deactivate UI
    BN->>AM: agentRespond(accepted: true)
    deactivate BN
    AM-->>D: Success
    deactivate AM
    
    D-->>BN: paired = true (Pair() completes)
    deactivate D
    BN-->>UI: Update UI (Paired)
    
    %% Explicit connection sequence to ensure stable profiles
    BN->>D: Disconnect() (Reset implicit pair connection)
    activate D
    D-->>BN: Success
    deactivate D
    BN->>D: Connect()
    activate D
    D->>M: Connect Profiles (A2DP, AVRCP)
    activate M
    M-->>D: Profiles Connected
    deactivate M
    D-->>BN: Connected = true
    deactivate D
    
    %% Apply device blocks to prevent interference
    loop For each OTHER paired device
        BN->>O: SetProperty("Blocked", true)
        activate O
        O-->>BN: Success
        deactivate O
    end
    
    BN-->>UI: Update UI (Connected)
    deactivate BN
```

## 3. Connecting Saved Device
```mermaid
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant D as Device1 (bluez)
    participant O as Other Devices (bluez)

    UI->>BN: connect()
    activate BN
    BN->>D: SetProperty("Blocked", false)
    activate D
    D-->>BN: Success
    deactivate D
    BN->>D: Connect()
    activate D
    
    alt Connection Success
        D->>M: Connect Profiles (A2DP, AVRCP, HFP)
        activate M
        M-->>D: Profiles Connected
        deactivate M
        D-->>BN: Property changed (Connected = true)
        
        loop For each OTHER paired device
            BN->>O: SetProperty("Blocked", true)
            activate O
            O-->>BN: Success
            deactivate O
        end
        
        BN-->>UI: Update UI (Connected)
    else Connection Failed / Timeout
        D-->>BN: Error (org.bluez.Error.Failed)
        BN-->>UI: Catch Exception & Revert UI
    end
    deactivate D
    deactivate BN
```

## 4. Disconnect
```mermaid
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant D as Device1 (bluez)
    participant O as Other Devices (bluez)

    UI->>BN: disconnect()
    activate BN
    BN->>D: Disconnect()
    activate D
    D->>M: Disconnect Profiles
    activate M
    M-->>D: Profiles Disconnected
    deactivate M
    D-->>BN: Property changed (Connected = false)
    deactivate D
    
    loop For each paired device
        BN->>O: SetProperty("Blocked", false)
        activate O
        O-->>BN: Success
        deactivate O
    end
    
    BN-->>UI: Update UI (Disconnected)
    deactivate BN
```

## 5. Removing
```mermaid
sequenceDiagram
    participant M as Mobile
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant A as Adapter1 (bluez)
    participant D as Device1 (bluez)
    participant O as Other Devices (bluez)

    UI->>BN: removeDevice()
    activate BN
    
    opt If connected
        BN->>D: Disconnect()
        activate D
        D->>M: Disconnect
        activate M
        M-->>D: Disconnected
        deactivate M
        D-->>BN: Success
        deactivate D
        
        loop For each paired device
            BN->>O: SetProperty("Blocked", false)
            activate O
            O-->>BN: Success
            deactivate O
        end
    end
    
    BN->>A: RemoveDevice(Device1 ObjectPath)
    activate A
    A->>M: Remove Bonding
    activate M
    M-->>A: Bonding Removed
    deactivate M
    A-->>BN: deviceRemoved (Device1)
    deactivate A
    BN-->>UI: Update UI (Device Removed)
    deactivate BN
```

## 6. Switching
```mermaid
sequenceDiagram
    participant M1 as Mobile 1 (Old)
    participant M2 as Mobile 2 (New)
    participant UI as Homescreen UI
    participant BN as bluez_native
    participant D1 as Device1 (bluez)
    participant D2 as Device2 (bluez)
    participant O as Other Devices (bluez)

    UI->>BN: pairAndConnect(Mobile 2)
    activate BN
    %% Prepare new device
    BN->>D2: SetProperty("Blocked", false)
    activate D2
    D2-->>BN: Success
    deactivate D2
    
    BN->>D2: SetProperty("Trusted", true)
    activate D2
    D2-->>BN: Success
    deactivate D2

    %% Disconnect current device first
    BN->>D1: Disconnect()
    activate D1
    D1->>M1: Disconnect
    activate M1
    M1-->>D1: Disconnected
    deactivate M1
    D1-->>BN: Property changed (Connected = false)
    deactivate D1
    
    BN->>D2: Connect()
    activate D2
    
    alt Switching Success
        D2->>M2: Connect Profiles
        activate M2
        M2-->>D2: Profiles Connected
        deactivate M2
        D2-->>BN: Property changed (Connected = true)
        
        %% Apply device blocks to prevent interference
        loop For each OTHER paired device (including Device 1)
            BN->>O: SetProperty("Blocked", true)
            activate O
            O-->>BN: Success
            deactivate O
        end
        
        BN-->>UI: Update UI (Switched)
    else Switching Failed (Rollback)
        D2-->>BN: Error (org.bluez.Error.Failed)
        
        BN->>D1: SetProperty("Blocked", false)
        activate D1
        D1-->>BN: Success
        deactivate D1
        
        BN->>D1: Connect() (Best-effort restore old connection)
        activate D1
        D1->>M1: Connect
        activate M1
        M1-->>D1: Connected
        deactivate M1
        D1-->>BN: Property changed (Connected = true)
        deactivate D1
        
        loop For each OTHER paired device (including Device 2)
            BN->>O: SetProperty("Blocked", true)
            activate O
            O-->>BN: Success
            deactivate O
        end
        
        BN-->>UI: Revert UI (Re-connected Old)
    end
    deactivate D2
    deactivate BN
```
