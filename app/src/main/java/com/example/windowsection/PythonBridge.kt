package com.example.windowsection

import android.content.Context
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

object PythonBridge {
    @Volatile
    private var isInitialized = false

    fun initialize(context: Context) {
        if (!isInitialized) {
            synchronized(this) {
                if (!isInitialized) {
                    if (!Python.isStarted()) {
                        Python.start(AndroidPlatform(context.applicationContext))
                    }
                    isInitialized = true
                }
            }
        }
    }

    fun calculate(payloadJson: String): String {
        val py = Python.getInstance()
        val jsonModule = py.getModule("json")
        val dcModule = py.getModule("dataclasses")
        val pyService = py.getModule("python_backend.services.calculation_service")
            .get("CalculationService") ?: throw IllegalStateException("CalculationService not found in Python backend")

        val payloadObj = jsonModule.callAttr("loads", payloadJson)
        val pyKwargs = payloadObj.asMap()

        val cart = pyKwargs[PyObject.fromJava("cart")]
        val allowedPipes = pyKwargs[PyObject.fromJava("allowed_pipes")]
        val rates = pyKwargs[PyObject.fromJava("rates")]
        val coating = pyKwargs[PyObject.fromJava("coating")]?.toString() ?: "Powder"
        val weightType = pyKwargs[PyObject.fromJava("weight_type")]?.toString() ?: "Medium"
        val profit = pyKwargs[PyObject.fromJava("profit")]?.toDouble() ?: 10.0
        val transport = pyKwargs[PyObject.fromJava("transport")]?.toDouble() ?: 0.0
        val extra = pyKwargs[PyObject.fromJava("extra")]?.toDouble() ?: 0.0
        val useGst = pyKwargs[PyObject.fromJava("use_gst")]?.toBoolean() ?: true
        val billingMode = pyKwargs[PyObject.fromJava("billing_mode")]?.toString() ?: "actual"
        val minBilling = pyKwargs[PyObject.fromJava("min_billing")]?.toBoolean() ?: false
        val scrap = pyKwargs[PyObject.fromJava("scrap")]
        val extraItems = pyKwargs[PyObject.fromJava("extra_items")]

        val resultPy = pyService.callAttr(
            "calculate",
            cart,
            allowedPipes,
            rates,
            coating,
            weightType,
            profit,
            transport,
            extra,
            useGst,
            billingMode,
            minBilling,
            scrap,
            extraItems
        )

        val resultDict = dcModule.callAttr("asdict", resultPy)
        return jsonModule.callAttr("dumps", resultDict).toString()
    }
}
