import "polyfill-object.fromentries";
import matchAll from "string.prototype.matchall";
import { mount, unmount, type Component } from "svelte";

matchAll.shim();

import AdminNetworkView from "$components/AdminNetworkView.svelte";
import SettingsView from "$components/SettingsView.svelte";
import HelpView from "$components/HelpView.svelte";
import DialogHost, { showDialog } from "$dialogs/DialogHost.svelte";
import { handleConfigUpdate, setDisplayUnits } from "$lib/ConfigStore";
import { handleControllerStateUpdate } from "$lib/ControllerState";
import { registerControllerMethods } from "$lib/RegisterControllerMethods";

export function createComponent(component: string, target: HTMLElement, props: Record<string, any>) {
    const mountComponent = (component: Component<any>) => {
        const instance = mount(component, {
            target: target ?? document.createElement("div"),
            props
        });

        return { $destroy: () => unmount(instance) };
    };

    switch (component) {
        case "AdminNetworkView":
            return mountComponent(AdminNetworkView);

        case "SettingsView":
            return mountComponent(SettingsView);

        case "HelpView":
            return mountComponent(HelpView);

        case "DialogHost":
            return mountComponent(DialogHost);

        default:
            throw new Error("Unknown component");
    }
}

export {
    showDialog,
    handleControllerStateUpdate,
    handleConfigUpdate,
    registerControllerMethods,
    setDisplayUnits
};
