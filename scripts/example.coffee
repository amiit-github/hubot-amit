cleverbot = require('cleverbot-node')

module.exports = (robot) ->
    robot.respond /commands$/i, (msg) ->
        commands = """
        @groot - <chat with groot>
        @groot abstract|abs|what is <topic> - Prints a nice abstract of the given topic
        @groot what should I do about  - Get advice from Groot.
        @groot what do you think about
        @groot how do you handle 
        @groot I need some advice
        @groot time <city, country> - Return the time at the given location.
        @groot (currency|exchange) <value> <currency-code> (in|to|into) <other-currency-code> 
        """
        msg.send commands
    # Commands:
    #   hubot abstract <topic> - Prints a nice abstract of the given topic

    robot.respond /(abs|abstract|what is a|what is) (.+)/i, (res) ->
      console.log("Query : " + res.match[2])
      abstract_url = "http://api.duckduckgo.com/?format=json&q=#{encodeURIComponent(res.match[2])}"
      res.http(abstract_url)
      .header('User-Agent', 'Hubot Abstract Script')
      .get() (err, _, body) ->
        return res.send "Sorry, the tubes are broken." if err
        data = JSON.parse(body.toString("utf8"))
        return unless data
        topic = data.RelatedTopics[0] if data.RelatedTopics and data.RelatedTopics.length
        if data.AbstractText
          # hubot abs numerology
          # Numerology is any study of the purported mystical relationship between a count or measurement and life.
          # http://en.wikipedia.org/wiki/Numerology
          res.send data.AbstractText
          res.send data.AbstractURL if data.AbstractURL
        else if topic and not /\/c\//.test(topic.FirstURL)
          # hubot abs astronomy
          # Astronomy is the scientific study of celestial objects.
          # http://duckduckgo.com/Astronomy
          res.send topic.Text
          res.send topic.FirstURL
        else if data.Definition
          # hubot abs contumacious
          # contumacious definition: stubbornly disobedient.
          # http://merriam-webster.com/dictionary/contumacious
          res.send data.Definition
          res.send data.DefinitionURL if data.DefinitionURL
        else
          res.send "I am Groot. I don't know anything about that."


    # Commands:
    #   hubot what should I do about (.*)
    #   hubot what do you think about (.*)
    #   hubot how do you handle (.*)
    #   hubot I need some advice
    #
    getAdvice = (msg, query) ->
      msg.http("http://api.adviceslip.com/advice/search/#{query}")
        .get() (err, res, body) ->
          results = JSON.parse body
          if results.message? then randomAdvice(msg) else msg.send(msg.random(results.slips).advice)

    randomAdvice = (msg) ->
      msg.http("http://api.adviceslip.com/advice")
        .get() (err, res, body) ->
          results = JSON.parse body
          advice = if err then "You're on your own, bud" else results.slip.advice
          msg.send advice


    robot.respond /what (do you|should I) do (when|about) (.*)/i, (msg) ->
      getAdvice msg, msg.match[3]

    robot.respond /how do you handle (.*)/i, (msg) ->
      getAdvice msg, msg.match[1]

    robot.respond /(.*) some advice about (.*)/i, (msg) ->
      getAdvice msg, msg.match[2]

    robot.respond /(.*) think about (.*)/i, (msg) ->
      getAdvice msg, msg.match[2]

    robot.respond /(.*) advice$/i, (msg) ->
      randomAdvice(msg)


    # hubot time <city, country> - Return the time at the given location.

    robot.respond /time (.*)/i, (msg) ->
      console.log("Query : " + msg.match[1])
      unless process.env.HUBOT_WORLD_WEATHER_KEY
        msg.send 'Please, set HUBOT_WORLD_WEATHER_KEY environment variable'
        return
      msg.http("http://api.worldweatheronline.com/free/v2/tz.ashx")
        .query({
          q: msg.match[1]
          key: process.env.HUBOT_WORLD_WEATHER_KEY
          format: 'json'
        })
        .get() (err, res, body) ->
          try
            result = JSON.parse(body)['data']
            city = result['request'][0]['query']
            currentTime = result['time_zone'][0]['localtime'].slice 11
            msg.send "Current time in #{city} ==> #{currentTime}"
          catch error
            msg.send "Sorry, no city found. Please, check your input and try it again"

    # Commands: Cleverbot
    #   hubot - <input>
    c = new cleverbot()

    robot.respond /- (.*)/i, (msg) ->
      data = msg.match[1].trim()
      c.write(data, (c) => msg.send(c.message))

    # Commands:
    #   hubot (currency|currencies) - list the supported currency codes
    #   hubot supported (currency|currencies) - list the supported currency codes
    #   hubot (currency|exchange) rate <currency-code> - list USD, GBP, and EUR exchange rates for <currency-code>
    #   hubot (currency|exchange) <value> <currency-code> (in|to|into) <other-currency-code> - convert <value> from <currency-code> to <other-currency-code>
    #