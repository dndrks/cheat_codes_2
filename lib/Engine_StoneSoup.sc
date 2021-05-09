// CroneEngine_StoneSoup
Engine_StoneSoup : CroneEngine {
  var <synth;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    synth = {
      arg amp=1,bpm=120,
      effect_phaser=0,effect_distortion=0,effect_delay=0,
      effect_bitcrush,bitcrush_bits=10,bitcrush_rate=12000, // this has parameters
      effect_strobe=0,effect_vinyl=0,effect_rlpf=0,
	  effect_pshift = 0,pshift_ratio = 0.5, pshift_chunk = 0.0;
      var in;
      in = SoundIn.ar([0,1]);

      // TODO: what is a good order for these?

      // phaser
      in = (in*(1-effect_phaser))+(effect_phaser*CombC.ar(in,1,SinOsc.kr(1/7).range(500,1000).reciprocal,0.05*SinOsc.kr(1/7.1).range(-1,1)));

      // distortion
      effect_distortion = Lag.kr(effect_distortion,0.5);
      in = (in*(1-(effect_distortion>0)))+(in*effect_distortion).tanh;

      // delay 
      in = (in*(1-effect_delay))+(effect_delay*CombC.ar(in,5,0.2,4));
      // TODO: explode some options

      // bitcrush
      in = (in*(1-effect_bitcrush))+(effect_bitcrush*Decimator.ar(in,Lag.kr(bitcrush_rate,1),Lag.kr(bitcrush_bits,1)));

      // strobe
      in = ((effect_strobe<1)*in)+((effect_strobe>0)*in*SinOsc.ar(bpm/60));

      // vinyl wow + compressor
      in=(effect_vinyl<1*in)+(effect_vinyl>0* Limiter.ar(Compander.ar(in,in,0.5,1.0,0.1,0.1,1,2),dur:0.0008));
      in =(effect_vinyl<1*in)+(effect_vinyl>0* DelayC.ar(in,0.01,VarLag.kr(LFNoise0.kr(1),1,warp:\sine).range(0,0.01)));                
      // TODO: add bandpass + vinyl sound for vinyl effect?

      // TODO: RLPF?

      // TODO: RHPF?

      // TODO: flanger?

      // TODO: pitch shifter?
	  in = (in*(1-effect_pshift))+(effect_pshift*Squiz.ar(in, pshift_ratio, pshift_chunk,0.01,1.0,0.0));

      // TODO: greyhole?

      // TOOD: stutter?

      // TODO: your favorite ??????

      Out.ar(0, in*Lag.kr(amp,1));
    }.play( target: context.xg);

    this.addCommand("amp", "f", { arg msg;
      synth.set(\amp, msg[1]);
    });

    this.addCommand("bpm", "f", { arg msg;
      synth.set(\bpm, msg[1]);
    });

    this.addCommand("phaser", "f", { arg msg;
      synth.set(\effect_phaser, msg[1]);
    });

    this.addCommand("distortion", "f", { arg msg;
      synth.set(\effect_distortion, msg[1]);
    });

    this.addCommand("delay", "f", { arg msg;
      synth.set(\effect_delay, msg[1]);
    });

    this.addCommand("strobe", "f", { arg msg;
      synth.set(\effect_strobe, msg[1]);
    });

    this.addCommand("vinyl", "f", { arg msg;
      synth.set(\effect_vinyl, msg[1]);
    });
	
	this.addCommand("rlpf", "f", { arg msg;
      synth.set(\effect_rlpf, msg[1]);
    });
		
			this.addCommand("pshift", "fff", { arg msg;
      synth.set(
		\effect_pshift, msg[1],
		\pshift_ratio, msg[2],
		\pshift_chunk, msg[3],
       );
    });

    this.addCommand("bitcrush", "fff", { arg msg;
      synth.set(
        \effect_bitcrush, msg[1],
        \bitcrush_bits, msg[2],
        \bitcrush_rate, msg[3],
      );
    });
  }

  free {
    synth.free;
  }
}