package io.github.knightstour;

import android.annotation.SuppressLint;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.app.Activity;

/**
 * Hosts the whole game, which lives inside the APK as assets/index.html.
 * There is no network access of any kind: the app declares no INTERNET
 * permission, and every external navigation is refused below.
 */
public class MainActivity extends Activity {

    private static final String GAME_URL = "file:///android_asset/index.html";
    private WebView web;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);

        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#140828"));

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        // localStorage keeps the player's progress between launches
        s.setDomStorageEnabled(true);
        // sounds must be able to start without a tap
        s.setMediaPlaybackRequiresUserGesture(false);
        // the page does its own fluid scaling; keep the browser out of it
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        // honour the page's own <meta name="viewport"> exactly as a browser does,
        // so the fluid vmin/clamp() layout scales the same way it did on the web
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(true);
        s.setTextZoom(100);
        s.setCacheMode(WebSettings.LOAD_NO_CACHE);

        // Refuse to navigate anywhere but the bundled page.
        web.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) {
                String url = r.getUrl() == null ? "" : r.getUrl().toString();
                return !url.startsWith("file:///android_asset/");
            }

            @SuppressWarnings("deprecation")
            @Override
            public boolean shouldOverrideUrlLoading(WebView v, String url) {
                return url == null || !url.startsWith("file:///android_asset/");
            }
        });

        setContentView(web);
        hideSystemBars();

        if (state == null) {
            web.loadUrl(GAME_URL);
        } else {
            web.restoreState(state);
        }
    }

    private void hideSystemBars() {
        getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            web.setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        }
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideSystemBars();
    }

    @Override
    protected void onSaveInstanceState(Bundle out) {
        super.onSaveInstanceState(out);
        web.saveState(out);
    }

    @Override
    public void onBackPressed() {
        // The game is a single page; the back gesture should leave the app
        // rather than walk a history the player never built.
        finish();
    }
}
