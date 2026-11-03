# Touch controls — NOT COMPLETED
Required engine snapshot: player validity, loading/pause, current entity and vehicle class, camera context. Atomic context snapshot published to UI; no timer/tap-based vehicle guessing. Layout states ON_FOOT, GROUND_VEHICLE, AIRCRAFT, LOADING, PAUSED. Transition releases incompatible held actions and retains meaningful analog intent without stuck buttons. Swipe camera default; optional full PAD; separate layout profiles with safe-area and overlap validation.

No engine adapter means no honest live context feed yet. The import diagnostic app does not pretend touch buttons are connected to GTA.
