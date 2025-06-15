local soundscripts = {}

soundscripts.closeSounds = {
    "timedoor/timedoor_close1.wav",
    "timedoor/timedoor_close2.wav",
    "timedoor/timedoor_close3.wav",
    "timedoor/timedoor_close4.wav",
}

soundscripts.glitchyCloseSounds = {
    "timedoor/unstable/glitchytimedoor_close1.wav",
    "timedoor/unstable/glitchytimedoor_close2.wav",
}

soundscripts.openSounds = {
    "timedoor/timedoor_open1.wav",
    "timedoor/timedoor_open2.wav",
}

soundscripts.glitchyOpenSounds = {
    "timedoor/unstable/glitchytimedoor_open1.wav",
    "timedoor/unstable/glitchytimedoor_open2.wav",
}

soundscripts.travelSounds = {
    "timedoor/timedoor_travel1.wav",
    "timedoor/timedoor_travel2.wav",
    "timedoor/timedoor_travel3.wav",
    "timedoor/timedoor_travel4.wav",
    "timedoor/timedoor_travel5.wav",
    "timedoor/timedoor_travel6.wav",
}

soundscripts.glitchyTravelSounds = {
    "timedoor/unstable/glitchytimedoor_travel1.wav",
    "timedoor/unstable/glitchytimedoor_travel2.wav",
    "timedoor/unstable/glitchytimedoor_travel3.wav",
}

local function PlayRandomSoundFromList(soundList, pos, volume, pitch)
    volume = volume or 1.0
    pitch = pitch or 100
    local soundPath = soundList[math.random(#soundList)]

    sound.Play(soundPath, pos, 80, pitch, volume)
end

function soundscripts.PlayCloseSound(pos)
    PlayRandomSoundFromList(soundscripts.closeSounds, pos)
end

function soundscripts.PlayOpenSound(pos)
    PlayRandomSoundFromList(soundscripts.openSounds, pos)
end

function soundscripts.PlayTravelSound(pos)
    PlayRandomSoundFromList(soundscripts.travelSounds, pos)
end

function soundscripts.PlayGlitchyCloseSound(pos)
    PlayRandomSoundFromList(soundscripts.glitchyCloseSounds, pos)
end

function soundscripts.PlayGlitchyOpenSound(pos)
    PlayRandomSoundFromList(soundscripts.glitchyOpenSounds, pos)
end

function soundscripts.PlayGlitchyTravelSound(pos)
    PlayRandomSoundFromList(soundscripts.glitchyTravelSounds, pos)
end

return soundscripts
