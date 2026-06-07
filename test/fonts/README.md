# Test fonts

`Tinos-Regular.ttf` is downloaded from the
[Google Fonts repository](https://github.com/google/fonts/blob/main/ofl/tinos/Tinos-Regular.ttf)
and is used to verify loading caller-provided font data.

`NotoSansSC-Test.ttf` is a small `text=` subset downloaded through Google Fonts
CSS2 and is used only by the parent application's multilingual resolver tests.

`Roboto-Hello.woff2` is a browser-negotiated CSS2 `text=Hello` subset used to
verify WOFF2 decoding at the Rust font database boundary.
