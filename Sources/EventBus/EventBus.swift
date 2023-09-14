import Foundation

// MARK: - EventBus

/// An event bus that you can subscribe or publish messages about special topics.
public final class EventBus {
    /// A global event bus.
    public static let global = EventBus()
    
    private let lock = NSRecursiveLock()
    
    private var subscribers: [Int: [Int: (any EventBusTopic) -> Void]] = [:]
    
    public init() {}
    
    // MARK: - Send Messages
    
    public func send(_ topic: some EventBusTopic) {
        lock.lock()
        defer { lock.unlock() }
        
        let topicKey = ObjectIdentifier(type(of: topic)).hashValue
        subscribers[topicKey]?.values.forEach { $0(topic) }
    }
    
    // MARK: - Subscription
    public func subscribe<Topic: EventBusTopic>(
        _ topic: Topic.Type,
        client: AnyObject,
        on queue: DispatchQueue = .main,
        receiveMessageHandler: @escaping (Topic) -> Void
    ) {
        subscribe(
            topic,
            client: ObjectIdentifier(client).hashValue,
            on: queue,
            receiveMessageHandler: receiveMessageHandler
        )
    }

    public func subscribe<Topic: EventBusTopic>(
        _ topic: Topic.Type,
        client: AnyHashable,
        on queue: DispatchQueue? = .main,
        receiveMessageHandler: @escaping (Topic) -> Void
    ) {
        lock.lock()
        defer { lock.unlock() }
        let client = client.hashValue
        
        let topicKey = ObjectIdentifier(topic.self).hashValue
        if var clients = subscribers[topicKey] {
            clients[client] = { [weak queue] in
                if let event = $0 as? Topic {
                    if let queue {
                        queue.async {
                            receiveMessageHandler(event)
                        }
                    } else {
                        receiveMessageHandler(event)
                    }
                }
            }
            subscribers[topicKey] = clients
        } else {
            subscribers[topicKey] = [
                client: { [weak queue] in
                    if let event = $0 as? Topic {
                        if let queue {
                            queue.async {
                                receiveMessageHandler(event)
                            }
                        } else {
                            receiveMessageHandler(event)
                        }
                    }
                },
            ]
        }
    }
    
    // MARK: - Unsubscription
    
    public func unsubscribeAll(_ client: AnyObject) {
        unsubscribeAll(ObjectIdentifier(client).hashValue)
    }

    public func unsubscribeAll(_ client: AnyHashable) {
        lock.lock()
        defer { lock.unlock() }
        
        let client = client.hashValue
        
        for topic in subscribers.keys {
            subscribers[topic]?.removeValue(forKey: client)
        }
    }
    
    public func unsubscribe(_ topic: (some EventBusTopic).Type, client: AnyObject) {
        unsubscribe(topic, client: ObjectIdentifier(client).hashValue)
    }

    public func unsubscribe(_ topic: (some EventBusTopic).Type, client: AnyHashable) {
        lock.lock()
        defer { lock.unlock() }
        
        let client = client.hashValue
        
        let topicKey = ObjectIdentifier(topic.self).hashValue
        subscribers[topicKey]?.removeValue(forKey: client)
    }
}

// MARK: - EventBusTopic

/// Any objects(class, struct, enum) conforming to the `EventBusTopic` protoocl can be as messages to be published or receives.
public protocol EventBusTopic {}
