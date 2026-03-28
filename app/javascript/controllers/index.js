// Import all controllers manually (esbuild doesn't support import.meta.glob)
import { application } from "./application"

import BarcodeScannerController from "./barcode_scanner_controller"
import HelloController from "./hello_controller"
import LibraryDropdownController from "./library_dropdown_controller"
import LibraryFormController from "./library_form_controller"
import SettingsFormController from "./settings_form_controller"
import SlimSelectController from "./slim_select_controller"

application.register("barcode-scanner", BarcodeScannerController)
application.register("hello", HelloController)
application.register("library-dropdown", LibraryDropdownController)
application.register("library-form", LibraryFormController)
application.register("settings-form", SettingsFormController)
application.register("slim-select", SlimSelectController)