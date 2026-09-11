pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

Item {
    id: root

    // Agente Polkit oficial de Quickshell
    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            console.warn("[PolkitService] Solicitud de autenticación iniciada para:", agent.flow ? agent.flow.actionId : "desconocido");
            root._manualFailed = false;
            root._manualErrorMessage = "";
        }

        onFlowChanged: {
            if (agent.flow) {
                console.warn("[PolkitService] Flujo activo asignado:", agent.flow.actionId, "mensaje:", agent.flow.message);
            }
        }
    }

    readonly property bool isRegistered: agent.isRegistered
    readonly property bool isActive: agent.isActive && agent.flow !== null
    readonly property var currentFlow: agent.flow

    // Propiedades descriptivas de la solicitud actual
    readonly property string message: {
        if (!currentFlow) return "";
        let m = currentFlow.message;
        if (m && m.length > 0) return m;
        return "Se requiere autenticación para realizar esta acción.";
    }

    readonly property string actionId: currentFlow ? (currentFlow.actionId || "") : ""
    readonly property string iconName: currentFlow ? (currentFlow.iconName || "") : ""
    readonly property string inputPrompt: currentFlow ? (currentFlow.inputPrompt || "Contraseña:") : "Contraseña:"
    readonly property bool responseVisible: currentFlow ? currentFlow.responseVisible : false

    // Propiedades reactivas del flujo
    readonly property bool flowFailed: currentFlow ? currentFlow.failed : false
    readonly property bool flowSuccessful: currentFlow ? currentFlow.isSuccessful : false
    readonly property bool flowCompleted: currentFlow ? currentFlow.isCompleted : false
    readonly property string supplementaryMessage: currentFlow ? (currentFlow.supplementaryMessage || "") : ""
    readonly property bool supplementaryIsError: currentFlow ? currentFlow.supplementaryIsError : false

    // Estado reactivo consolidado de error y éxito
    property bool _manualFailed: false
    property string _manualErrorMessage: ""

    readonly property bool authFailed: _manualFailed || flowFailed || (supplementaryIsError && supplementaryMessage !== "")
    readonly property string errorMessage: {
        if (_manualErrorMessage !== "") return _manualErrorMessage;
        if (supplementaryMessage !== "") return supplementaryMessage;
        if (flowFailed) return "Contraseña incorrecta. Inténtelo de nuevo.";
        return "";
    }
    readonly property bool isSuccess: flowSuccessful

    Connections {
        target: root.currentFlow
        ignoreUnknownSignals: true

        function onAuthenticationFailed() {
            console.warn("[PolkitService] Signal: AuthenticationFailed");
            root._manualFailed = true;
            if (root.currentFlow && root.currentFlow.supplementaryMessage) {
                root._manualErrorMessage = root.currentFlow.supplementaryMessage;
            } else {
                root._manualErrorMessage = "Contraseña incorrecta. Inténtelo de nuevo.";
            }
        }

        function onAuthenticationSucceeded() {
            console.warn("[PolkitService] Signal: AuthenticationSucceeded");
            root._manualFailed = false;
            root._manualErrorMessage = "";
        }

        function onAuthenticationRequestCancelled() {
            console.warn("[PolkitService] Signal: AuthenticationRequestCancelled");
            root._manualFailed = false;
            root._manualErrorMessage = "";
        }
    }

    // Métodos públicos
    function submit(password) {
        if (!currentFlow) {
            console.warn("[PolkitService] Submit llamado sin flujo activo");
            return;
        }
        console.warn("[PolkitService] Enviando credenciales...");
        root._manualFailed = false;
        root._manualErrorMessage = "";
        currentFlow.submit(password);
    }

    function cancel() {
        if (!currentFlow) {
            console.warn("[PolkitService] Cancel llamado sin flujo activo");
            return;
        }
        console.warn("[PolkitService] Cancelando solicitud...");
        root._manualFailed = false;
        root._manualErrorMessage = "";
        currentFlow.cancelAuthenticationRequest();
    }
}
