﻿package {

  import flash.events.Event;
  import flash.events.NetStatusEvent;
  import flash.net.NetConnection;
  import flash.net.NetStream;
  import flash.media.Microphone;
  import flash.media.MicrophoneEnhancedOptions;
  import flash.media.MicrophoneEnhancedMode;
  import flash.media.SoundCodec;
  import flash.display.MovieClip;

  import flash.external.ExternalInterface;

  public class Blackbox extends MovieClip {
    var mic: Microphone;
    var netStreams: Array = new Array();
 
    public function Blackbox() {
      ExternalInterface.addCallback("publish", publishStream);
      ExternalInterface.addCallback("subscribe", subscribeStream);
      ExternalInterface.call("flashInitialized");
    }

    function publishStream(stream: String) {
      var nc: NetConnection = new NetConnection();
      nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler(sendStream, nc, stream));
      nc.connect("rtmp://kluuu-staging.panter.ch/discussions");
    }

    function subscribeStream(stream: String) {
      var nc: NetConnection = new NetConnection();
      nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler(receiveStream, nc, stream));
      nc.connect("rtmp://kluuu-staging.panter.ch/discussions");
    }

    function sendStream(nc: NetConnection, stream: String) {
      var options:MicrophoneEnhancedOptions = new MicrophoneEnhancedOptions();
      options.mode = MicrophoneEnhancedMode.FULL_DUPLEX;
      options.autoGain = false;
      options.echoPath = 128;
      options.nonLinearProcessing = true;

      mic = Microphone.getEnhancedMicrophone();
      mic.setSilenceLevel(0, 2000);
      mic.enhancedOptions = options;
      mic.codec = SoundCodec.SPEEX;
      mic.encodeQuality = 11;
      mic.framesPerPacket = 1;
      mic.gain = 60;
      mic.setUseEchoSuppression(true);

      var ns: NetStream = new NetStream(nc);
      ns.attachAudio(mic);
      ns.publish(stream, "live");
      netStreams.push(ns);
    }
 
    function receiveStream(nc: NetConnection, stream: String) {
      var ns: NetStream = new NetStream(nc);
      ns.receiveVideo(false);
      ns.play(stream);
      netStreams.push(ns);
    }
 
    function netStatusHandler(func: Function, nc: NetConnection, stream: String): Function {
      return function(event: NetStatusEvent) {
        if (event.info.code == "NetConnection.Connect.Success") {
          func(nc, stream);
          log("connected to " + stream);
        } else {
          log(event.info.code);
        }
      }
    }

    function log(msg) {
      ExternalInterface.call("flashLog", msg);
    }
  }
}
