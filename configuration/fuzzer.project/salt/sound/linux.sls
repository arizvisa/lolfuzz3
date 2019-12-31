Enable the audio device using snd_aloop:
    kmod.present:
        - name: snd_aloop
