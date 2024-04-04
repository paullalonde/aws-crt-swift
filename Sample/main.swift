print("Sample Starting")

import AwsCommonRuntimeKit
import AwsCMqtt
import Foundation

Logger.initialize(pipe: stdout, level: LogLevel.debug)
print("Initializing CommonRutimeKit")
CommonRuntimeKit.initialize()

// Direct connect to mosquitto succeeds
func buildDirectClient() throws -> Mqtt5Client {
    print("Building Direct Mqtt Client")
    let elg = try EventLoopGroup()
    let resolver = try HostResolver.makeDefault(eventLoopGroup: elg)
    let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: resolver)
    let socketOptions = SocketOptions()

    let connectOptions = MqttConnectOptions(keepAliveInterval: 120)
    let clientOptions = MqttClientOptions(
                                        hostName: "localhost",
                                        port: 1883,
                                        bootstrap: clientBootstrap,
                                        socketOptions: socketOptions,
                                        connectOptions: connectOptions,
                                        onLifecycleEventStoppedFn: onLifecycleEventStopped,
                                        onLifecycleEventAttemptingConnectFn: onLifecycleEventAttemptingConnect,
                                        onLifecycleEventConnectionSuccessFn: onLifecycleEventConnectionSuccess,
                                        onLifecycleEventConnectionFailureFn: onLifecycleEventConnectionFailure,
                                        onLifecycleEventDisconnectionFn: onLifecycleEventDisconnect)

    print("Returning Mqtt Client")
    return try Mqtt5Client(clientOptions: clientOptions)
}

func onLifecycleEventStopped(lifecycleStoppedData: LifecycleStoppedData) -> Void {
    print("\nClient Set Lifecycle Event Stopped Function Called \n")
}

func onLifecycleEventAttemptingConnect(lifecycleAttemptingConnectData: LifecycleAttemptingConnectData) -> Void {
    print("\nClient Set Lifecycle Event Attempting Connect Function Called \n")
}

func onLifecycleEventConnectionSuccess(lifecycleConnectionSuccessData: LifecycleConnectionSuccessData) -> Void {
    print("\nClient Set Lifecycle Event Connection Success Function Called \n")
    processConnack(connackPacket: lifecycleConnectionSuccessData.connackPacket)
    processNegotiatedSettings(negotiatedSettings: lifecycleConnectionSuccessData.negotiatedSettings)
}

func onLifecycleEventConnectionFailure(lifecycleConnectionFailureData: LifecycleConnectionFailureData){
    print("\nClient Set Lifecycle Event Connection Failure Function Called \n")
    print("     =======ERROR CODE=======")
    print("     crtError: \(lifecycleConnectionFailureData.crtError)\n")
    if let connackPacket = lifecycleConnectionFailureData.connackPacket {
        processConnack(connackPacket: connackPacket)
    } else {
        print("     =======NO CONNACK PACKET=======\n")
    }
}

func onLifecycleEventDisconnect(lifecycleDisconnectData: LifecycleDisconnectData) -> Void {
    print("\nClient Set Lifecycle Event Disconnect Function Called \n")
    print("     =======ERROR CODE=======")
    print("     crtError: \(lifecycleDisconnectData.crtError)\n")
    if let disconnectPacket = lifecycleDisconnectData.disconnectPacket {
        processDisconnectPacket(disconnectPacket: disconnectPacket)
    } else {
        print("     =======NO DISCONNECT PACKET=======\n")
    }
}

func buildMtlsClient() throws -> Mqtt5Client {
    print("Building Mtls Mqtt Client")
    let elg = try EventLoopGroup()
    let resolver = try HostResolver.makeDefault(eventLoopGroup: elg)
    let clientBootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: resolver)
    let socketOptions = SocketOptions()

    let tlsOptions = try TLSContextOptions.makeMtlsFromFilePath(
        certificatePath:
            "/Volumes/workplace/swift-mqtt/aws-crt-swift/.vscode/aws-sdk-cert.pem",
        privateKeyPath:
            "/Volumes/workplace/swift-mqtt/aws-crt-swift/.vscode/aws-sdk-key.pem")
    // tlsOptions.setAlpnList(["x-amzn-mqtt-ca"])
    let tlsContext = try TLSContext(options: tlsOptions, mode: .client)


    let connectOptions = MqttConnectOptions(keepAliveInterval: 120)
    let clientOptions = MqttClientOptions(
                                        hostName: "a2yvr5l8sc9814-ats.iot.us-east-1.amazonaws.com",
                                        // port: 443, // to connect to 443 we need to set alpn
                                        port: 8883, // connect to 8883 which expects mqtt
                                        bootstrap: clientBootstrap,
                                        socketOptions: socketOptions,
                                        tlsCtx: tlsContext,
                                        connectOptions: connectOptions,
                                        onLifecycleEventStoppedFn: onLifecycleEventStopped,
                                        onLifecycleEventAttemptingConnectFn: onLifecycleEventAttemptingConnect,
                                        onLifecycleEventConnectionSuccessFn: onLifecycleEventConnectionSuccess,
                                        onLifecycleEventConnectionFailureFn: onLifecycleEventConnectionFailure,
                                        onLifecycleEventDisconnectionFn: onLifecycleEventDisconnect)

    print("Returning Mqtt Client")
    return try Mqtt5Client(clientOptions: clientOptions)
}

// let client = try buildDirectClient()
let client = try buildMtlsClient()
print("\nCalling start()\n")
client.start()

// for waiting/sleep
let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

// wait(seconds: 5)

// Wait x seconds with logging
func wait (seconds: Int) {
    print("          wait for \(seconds) seconds")
    let timeLeft = seconds - 1
    for i in (0...timeLeft).reversed() {
        _ = semaphore.wait(timeout: .now() + 1)
        print("          \(i) seconds left")
    }
}

func waitNoCountdown(seconds: Int) {
    print("          wait for \(seconds) seconds")
    _ = semaphore.wait(timeout: .now() + 1)
}

func nativeSubscribe(subscribePacket: SubscribePacket, completion: @escaping (Int, SubackPacket) -> Void) -> Int {
    print("[NATIVE CLIENT] SubscribePaket with topic '\(subscribePacket.subscriptions[0].topicFilter)' received for processing")

    // Simulate an asynchronous task.
    // This block is occuring in a background thread relative to the main thread.
    DispatchQueue.global().async {
        let nativeSemaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

        print("[NATIVE CLIENT] simulating 2 second delay for receiving a suback from broker for `\(subscribePacket.subscriptions[0].topicFilter)`")
        _ = nativeSemaphore.wait(timeout: .now() + 2)

        let subackPacket: SubackPacket = SubackPacket(
            reasonCodes: [SubackReasonCode.grantedQos1],
            userProperties: [UserProperty(name: "Topic", value: "\(subscribePacket.subscriptions[0].topicFilter)")])

        print("[NATIVE CLIENT] simulating calling the swift callback with an error code and subackPacket for `\(subscribePacket.subscriptions[0].topicFilter)`")
        completion(0, subackPacket)
        // if (Bool.random()){
        //     completion(5146, subackPacket)
        // } else {
        //     completion(0, subackPacket)
        // }
    }

    return 0
}

func subscribeAsync(subscribePacket: SubscribePacket) async throws -> SubackPacket {
    print("client.subscribeAsync() entered for `\(subscribePacket.subscriptions[0].topicFilter)`")

    // withCheckedThrowingContinuation is used as a bridge between native's callback asynchrnous code and Swift's async/await model
    // This func will pause until continuation.resume() is called

    return try await withCheckedThrowingContinuation { continuation in
        print("subscribeAsync try await withCheckedThrowingContinuation for '\(subscribePacket.subscriptions[0].topicFilter)` starting")
        // The completion callback to invoke when an ack is received in native
        func subscribeCompletionCallback(errorCode: Int, subackPacket: SubackPacket) {
            print("   subscribeCompletionCallback called for `\(subackPacket.userProperties![0].value)`")
            if errorCode == 0 {
                continuation.resume(returning: subackPacket)
            } else {
                continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: errorCode)))
            }
        }

        // Translate swift packet to native packet
        // We have a native callback for the operation
        // We have a pointer to the swift callback
        // aws_mqtt5_subscribe(nativePacket, nativeCallback)

        print("subscribeAsync nativeSubscribe within withCheckedThrowingContinuation for '\(subscribePacket.subscriptions[0].topicFilter)` starting")
        // represents the call to the native client
        let result = nativeSubscribe(
            subscribePacket: subscribePacket,
            completion: subscribeCompletionCallback)

        if result != 0 {
            continuation.resume(throwing: CommonRunTimeError.crtError(CRTError(code: -1)))
        }
    }
}

func subscribe(subscribePacket: SubscribePacket) -> Task<SubackPacket, Error> {
    return Task {
        print("Subscribe Task for `\(subscribePacket.subscriptions[0].topicFilter)` executing")
        return try await subscribeAsync(subscribePacket: subscribePacket)
    }
}

func processSuback(subackPacket: SubackPacket) {
    print("     =======SUBACK PACKET=======")
    print("     Processing suback")
    print("     Suback reasonCode: \(subackPacket.reasonCodes[0])")
    if let userProperties = subackPacket.userProperties {
        for property in userProperties {
            print("     \(property.name) : \(property.value)")
        }
    }
    print("     =====SUBACK PACKET END=====")
}

func processNegotiatedSettings(negotiatedSettings: NegotiatedSettings) {
    print("     =======NEGOTIATED SETTINGS=======")

    print("     maximumQos: \(negotiatedSettings.maximumQos)")

    print("     sessionExpiryInterval: \(negotiatedSettings.sessionExpiryInterval)")

    print("     receiveMaximumFromServer: \(negotiatedSettings.receiveMaximumFromServer)")

    print("     maximumPacketSizeToServer: \(negotiatedSettings.maximumPacketSizeToServer)")

    print("     topicAliasMaximumToServer: \(negotiatedSettings.topicAliasMaximumToServer)")

    print("     topicAliasMaximumToClient: \(negotiatedSettings.topicAliasMaximumToClient)")

    print("     serverKeepAlive: \(negotiatedSettings.serverKeepAlive)")

    print("     retainAvailable: \(negotiatedSettings.retainAvailable)")

    print("     wildcardSubscriptionsAvailable: \(negotiatedSettings.wildcardSubscriptionsAvailable)")

    print("     subscriptionIdentifiersAvailable: \(negotiatedSettings.subscriptionIdentifiersAvailable)")

    print("     sharedSubscriptionsAvailable: \(negotiatedSettings.sharedSubscriptionsAvailable)")

    print("     rejoinedSession: \(negotiatedSettings.rejoinedSession)")

    print("     clientId: \(negotiatedSettings.clientId)")

    print("=============================================")
}

func processConnack(connackPacket: ConnackPacket) {
    print("     =======CONNACK PACKET=======")

    print("     sessionPresent: \(connackPacket.sessionPresent)")

    print("     Connack reasonCode: \(connackPacket.reasonCode)")

    if let sessionExpiryInterval = connackPacket.sessionExpiryInterval {
        print("     sessionExpiryInterval: \(sessionExpiryInterval)")
    } else { print("     sessionExpirtyInterval: NONE") }

    if let receiveMaximum = connackPacket.receiveMaximum {
        print("     receiveMaximum: \(receiveMaximum)")
    } else { print("     receiveMaximum: NONE")}

    if let maximumQos = connackPacket.maximumQos {
        print("     maximumQos: \(maximumQos)")
    } else { print("    maximumQos: NONE") }

    if let retainAvailable = connackPacket.retainAvailable {
        print("     retainAvailable: \(retainAvailable)")
    } else {print("     retainAvailable: NONE")}

    if let maximumPacketSize = connackPacket.maximumPacketSize {
        print("     maximumPacketSize: \(maximumPacketSize)")
    } else {print("     maximumPacketSize: NONE")}

    if let assignedClientIdentifier = connackPacket.assignedClientIdentifier {
        print("     assignedClientIdentifier: \(assignedClientIdentifier)")
    } else {print("     assignedClientIdentifier: NONE")}

    if let topicAliasMaximum = connackPacket.topicAliasMaximum {
        print("     topicAliasMaximum: \(topicAliasMaximum)")
    } else {print("     topicAliasMaximum: NONE")}

    if let reasonString = connackPacket.reasonString {
        print("     reasonString: \(reasonString)")
    } else {print("     reasonString: NONE")}

    if let wildcardSubscriptionsAvailable = connackPacket.wildcardSubscriptionsAvailable {
        print("     wildcardSubscriptionsAvailable: \(wildcardSubscriptionsAvailable)")
    } else {print("     wildcardSubscriptionsAvailable: NONE")}

    if let subscriptionIdentifiersAvailable = connackPacket.subscriptionIdentifiersAvailable {
        print("     subscriptionIdentifiersAvailable: \(subscriptionIdentifiersAvailable)")
    } else {print("     subscriptionIdentifiersAvailable: NONE")}

    if let sharedSubscriptionAvailable = connackPacket.sharedSubscriptionAvailable {
        print("     sharedSubscriptionAvailable: \(sharedSubscriptionAvailable)")
    } else {print("     sharedSubscriptionAvailable: NONE")}

    if let serverKeepAlive = connackPacket.serverKeepAlive {
        print("     serverKeepAlive: \(serverKeepAlive)")
    } else {print("     serverKeepAlive: NONE")}

    if let responseInformation = connackPacket.responseInformation {
        print("     responseInformation: \(responseInformation)")
    } else {print("     responseInformation: NONE")}

    if let serverReference = connackPacket.serverReference {
        print("     serverReference: \(serverReference)")
    } else {print("     serverReference: NONE")}

    print("=============================================")

}

func processDisconnectPacket(disconnectPacket: DisconnectPacket) {
    print("     =======DISCONNECT PACKET=======")
    print("     Connack reasonCode: \(disconnectPacket.reasonCode)")

    if let sessionExpiryInterval = disconnectPacket.sessionExpiryInterval {
        print("     sessionExpiryInterval: \(sessionExpiryInterval)")
    } else {print("     sessionExpiryInterval: NONE")}

    if let reasonString = disconnectPacket.reasonString {
        print("     reasonString: \(reasonString)")
    } else {print("     reasonString: NONE")}

    if let serverReference = disconnectPacket.serverReference {
        print("     serverReference: \(serverReference)")
    } else {print("     serverReference: NONE")}

    print("=============================================")

}

// let subscribePacket: SubscribePacket = SubscribePacket(
//     topicFilter: "hello/world",
//     qos: QoS.atLeastOnce)

// // Ignore the returned Task
// _ = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Ignore",
//     qos: QoS.atLeastOnce))

// waitNoCountdown(seconds: 1)

// let taskUnused = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Task Unused",
//     qos: QoS.atLeastOnce))

// let task1 = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Within",
//     qos: QoS.atLeastOnce))
// do {
//     let subackPacket = try await task1.value
//     processSuback(subackPacket: subackPacket)
// } catch {
//     print("An error was thrown \(error)")
// }

// This passes to Native the operation, we don't care about result but the async function runs to completion
// async let _ = subscribeAsync(subscribePacket: subscribePacket)

// Syncronously wait for the subscribe to complete and return a suback
// let suback = try await subscribeAsync(subscribePacket: subscribePacket)

// Put subscribe into a Task to complete
// Task {
//     do {
//         let suback = try await subscribeAsync(subscribePacket: subscribePacket)
//         processSuback(subackPacket: suback)
//     } catch {
//         print("An error was thrown \(error)")
//     }
// }

// results in "'async' call in a function that does not support concurrency"
// needs to be contained in an async function to be used this way
// subscribeAsync(subscribePacket: subscribePacket)

// Drops out of scope immediately without passing op to native
// Task {
//     try await subscribeAsync(subscribePacket: subscribePacket)
// }

// func TestFunk() {
//     Task {
//         let result = try await subscribeAsync(subscribePacket: subscribePacket)
//         print("RESULT \(result.reasonCodes[0])")
//     }
// }
// TestFunk()

// _ = subscribe(subscribePacket: subscribePacket)

// _ = subscribe(subscribePacket: subscribePacket)

// let taskF = client.subscribe(subscribePacket: subscribePacket)
// let task =  Task { try await client.subscribeAsync(subscribePacket: subscribePacket) }

// async let ack = try subscribe(subscribePacket: subscribePacket).value
// try await client.subscribeAsync(subscribePacket: subscribePacket)

// Execute the operation from within a task block
// Task.detached {
//     let task1 = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Within",
//     qos: QoS.atLeastOnce))
//     do {
//         let subackPacket = try await task1.value
//         processSuback(subackPacket: subackPacket)
//     } catch {
//         print("An error was thrown \(error)")
//     }
// }

// waitNoCountdown(seconds: 1)

// // Execute the operation and store the task and then complete it in a task block.
// let task2 = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Store and task block",
//     qos: QoS.atLeastOnce))
// Task.detached {
//     do {
//         let subackPacket = try await task2.value
//         processSuback(subackPacket: subackPacket)
//     } catch {
//         print("An error was thrown \(error)")
//     }
// }

// waitNoCountdown(seconds: 1)
// let task3 = subscribe(subscribePacket: SubscribePacket(
//     topicFilter: "Store and nothing else",
//     qos: QoS.atLeastOnce))

// // Wait for the future to complete or until a timeout (e.g., 5 seconds)
// wait(seconds: 5)
// Task.detached {
//     do {
//         let subackTask3 = try await task3.value
//         processSuback(subackPacket: subackTask3)
//     } catch {
//         print("An error was thrown \(error)")
//     }
// }

wait(seconds: 10)

print("Stopping Client")
client.stop()

wait(seconds: 5)

// print("cleanUp CommonRuntimeKit")
// CommonRuntimeKit.cleanUp()

// print("Sample Ending")