//@ pragma UseQApplication
//@ pragma RespectSystemStyle
//@ pragma Env QT_QPA_PLATFORMTHEME = gtk3
//@ pragma Env QT_LOGGING_RULES = qt.qpa.services.warning=false
import Quickshell
import "modules/bar"

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
