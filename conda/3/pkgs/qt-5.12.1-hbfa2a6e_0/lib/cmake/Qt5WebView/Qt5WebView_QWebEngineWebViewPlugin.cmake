
add_library(Qt5::QWebEngineWebViewPlugin MODULE IMPORTED)

_populate_WebView_plugin_properties(QWebEngineWebViewPlugin RELEASE "webview/libqtwebview_webengine.so")

list(APPEND Qt5WebView_PLUGINS Qt5::QWebEngineWebViewPlugin)
