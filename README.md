# cheat codes 2 beta

a sample playground for norns

### requirements

### hard requirements:
- norns (201115 or later)

### encouraged:
- grid (128 only, all editions)
- arc
- OP-Z (see below)
- Midi Fighter Twister ([cheat codes template](https://github.com/dndrks/cheat-codes-docs/blob/main/assets/downloadables/cc-mft.mfs)) <~~ right-click and save
- max for live ([cheat codes osc control device](https://github.com/dndrks/cheat-codes-docs/blob/main/assets/downloadables/cc-osc.amxd)) <~~ right-click and save

### [documentation](https://github.com/dndrks/cheat-codes-docs/raw/main/assets/images/pdf/cheat_codes_2.pdf)

### [discussion](https://l.llllllll.co/cheat-codes-2)

---

#### OP-Z setup notes

you’ll need to make some adjustments to OP-Z’s MIDI settings, so grab a screen and navigate to the OP-Z’s MIDI SETUP menus!

for globals, make only the following active:

*MIDI IN ENABLE*  
*MIDI OUT ENABLE*  
*CLOCK IN ENABLE*  
*CLOCK OUT ENABLE*  

then, you’ll want to choose three tracks to control the three banks of cheat codes. how you set that up will depend on your end-goals, but make sure you take note of the midi channels for each track. if you’ve never edited the MIDI channel assignments for the tracks on your OP-Z, they’re likely set up as 1-16 – double check in the app, though!

you may also want to disable the OP-Z feature where changing tracks make a little “preview” sound of the instrument. if you connect to OP-Z using disk mode, there’s a config > general.json file you can edit. change "disable track preview" to true !

plug your op-z into norns using the USB-C charge cable. you should see OP-Z in your SYSTEM > DEVICES > MIDI list. please take note of which port it’s on (1/2/3/4).

in cc2’s PARAMS, go to MIDI setup :

enable MIDI control? yes  
MIDI control device whatever port your OP-Z is on  
enable MIDI echo? yes, this allows the encoders on OP-Z to be used like arc!  

from there, you’ll want to set the bank MIDI channels to match the tracks from the OP-Z. they’re defaulted to 1/2/3, which on a factory-set OP-Z are the first, second, and third tracks.
