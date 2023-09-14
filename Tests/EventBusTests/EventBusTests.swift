import XCTest
@testable import EventBus

final class EventBusTests: XCTestCase {
    
    func testStructTopic() throws {
        let eventBus = EventBus()
        let structTopic = StructTopic(text: "struct")
        
        var triggerCount: Int = 0
        
        eventBus.subscribe(StructTopic.self, client: 0) { topic in
            triggerCount += 1
            XCTAssertEqual(topic.text, "struct")
        }
        
        eventBus.send(structTopic)
        
        XCTAssertEqual(triggerCount, 1)
    }
    
    func testEnumTopic() throws {
        let eventBus = EventBus()
        let enumTopic = EnumTopic.one
        
        var triggerCount: Int = 0
        
        eventBus.subscribe(EnumTopic.self, client: 0) { topic in
            triggerCount += 1
            XCTAssertEqual(topic, .one)
        }
        
        eventBus.send(enumTopic)
        
        XCTAssertEqual(triggerCount, 1)
    }
    
    func testClassTopic() throws {
        let eventBus = EventBus()
        let classTopic = ClassTopic(text: "class")
        
        var triggerCount: Int = 0
        
        eventBus.subscribe(ClassTopic.self, client: 0) { topic in
            triggerCount += 1
            XCTAssertEqual(topic.text, "class")
        }
        
        eventBus.send(classTopic)
        
        XCTAssertEqual(triggerCount, 1)
    }
    
    func testSubscription() throws {
        struct TopicOne: EventBusTopic {}
        struct TopicTwo: EventBusTopic {}
        
        let eventBus = EventBus()
        
        eventBus.subscribe(TopicOne.self, client: 0) { _ in
            XCTFail("received unsubscribed topics")
        }
        
        eventBus.send(TopicTwo())
    }
    
    func testUnsubscription() throws {
        struct TopicOne: EventBusTopic {}
        
        let eventBus = EventBus()
        
        eventBus.subscribe(TopicOne.self, client: 0) { _ in
            XCTFail("received unsubscribed topics")
        }
        
        eventBus.unsubscribeAll(0)
        
        eventBus.send(TopicOne())
    }
}

extension EventBusTests {
    struct StructTopic: EventBusTopic {
        let text: String
    }
    
    enum EnumTopic: EventBusTopic {
        case one
        case two
    }
    
    class ClassTopic: EventBusTopic {
        let text: String
        
        init(text: String) {
            self.text = text
        }
    }
}
