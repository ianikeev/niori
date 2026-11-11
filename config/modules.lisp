;; Niori module systems to load at boot, in order.
;;
;; Niori - a modular desktop application built on CLOG.
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Copyright (C) 2026  Igor Anikeev
;;
;; Each entry is an independent ASDF system found under modules/.
;; Comment a line out to disable a module, or add your own module
;; system (its directory must contain a .asd with the same name).

(:niori-mod-medications
 :niori-mod-visits
 :niori-mod-tests
 :niori-mod-vaccinations)
