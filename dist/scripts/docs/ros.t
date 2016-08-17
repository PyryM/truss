-- ROS
-- ===

-- The ROS module provides ROS interoperability through the ROS websocket
-- bridge.

function rosExample(app)
    -- ### Initialization

    -- Create a Ros object. This has no options.
    local Ros = require("io/ros.t").Ros()

    -- Connect to the rosbridge server through its websocket URL.
    -- See [the ROS wiki](http://wiki.ros.org/rosbridge_suite/Tutorials/RunningRosbridge)
    -- on how to install and run rosbridge.
    local url = "ws://herb0:8080"
    Ros:connect(url)

    -- ### Topic creation

    -- Create a topic for publishing
    local publishTopicOptions = {
        topicName = "echo/return",
        messageType = "std_msgs/String",
        throttleRate = 0,
        latch = false,
        queueSize = 100
    }
    local publishTopic = Ros:topic(publishTopicOptions)
    publishTopic:advertise()

    -- Create a topic for subscribing
    local subscribeTopicOptions = {
        topicName = "echo/listen",
        messageType = "std_msgs/String",
        throttleRate = 0,
        latch = false,
        queueSize = 100
    }
    local subscribeTopic = Ros:topic(subscribeTopicOptions)
    local callback = function(topic, msg)
        log.info("Ros message: " .. msg.data)
        publishTopic:publish(msg)
    end
    subscribeTopic:subscribe(callback)

    -- ### Running/Updating

    -- It is necessary to call Ros:update() regularly (ideally each frame)
    for i = 1,6000 do
        Ros:update()
        app:yield()
    end

    -- ### Cleanup

    -- Topics can be unsubscribed and unadvertised, for subscribers/publishers
    publishTopic:unadvertise()
    subscribeTopic:unadvertise()

    -- Ros can disconnect from the server
    Ros:disconnect()
end

----------------------------------

-- Example setup stuff
-- -------------------

function init()
    -- Use the DocScaffold app to run our example script
    app = require("docs/docscaffold.t").DocScaffold({})
    app:startScript(rosExample)
end

function update()
    app:update()
end
