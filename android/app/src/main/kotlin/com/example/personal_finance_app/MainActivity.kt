package com.example.personal_finance_app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState) // <--- මෙය ඉහළින්ම තිබිය යුතුයි

        // App එකේ දත්ත Recent Apps වල සැඟවීමට සහ Screenshots Block කිරීමට
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}