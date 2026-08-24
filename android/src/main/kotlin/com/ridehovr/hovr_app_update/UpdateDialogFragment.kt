package com.ridehovr.hovr_app_update

import android.app.Dialog
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.res.colorResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.graphics.drawable.toDrawable
import androidx.core.net.toUri
import androidx.fragment.app.DialogFragment

private fun openPlayStore(context: Context) {
    val packageName = context.packageName
    try {
        context.startActivity(
            Intent(
                Intent.ACTION_VIEW,
                "market://details?id=$packageName".toUri(),
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
    } catch (_: android.content.ActivityNotFoundException) {
        context.startActivity(
            Intent(
                Intent.ACTION_VIEW,
                "https://play.google.com/store/apps/details?id=$packageName".toUri(),
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
    }
}

private fun restartProcess(context: Context) {
    ProcessRestarter.restart(context)
}

@Composable
private fun UpdateDialogContent(
    onSkipClick: () -> Unit,
    onUpdateClick: () -> Unit,
) {
    Column(
        modifier = Modifier
            .padding(24.dp)
            .background(Color.White)
            .widthIn(min = 280.dp),
    ) {
        Text(
            text = "Update Required",
            style = MaterialTheme.typography.titleLarge,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = "A new version of the app is available. Please update to continue.",
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(24.dp))
        Row(horizontalArrangement = Arrangement.Center) {
            Button(
                onClick = onSkipClick,
                colors = ButtonDefaults.buttonColors(
                    containerColor = colorResource(id = R.color.hovr_update_white),
                ),
                shape = RoundedCornerShape(50),
                modifier = Modifier.height(48.dp),
            ) {
                Text("Skip", color = Color.Black)
            }
            Spacer(modifier = Modifier.width(24.dp))
            Button(
                onClick = onUpdateClick,
                colors = ButtonDefaults.buttonColors(
                    containerColor = colorResource(id = R.color.hovr_update_green),
                ),
                shape = RoundedCornerShape(50),
                modifier = Modifier.height(48.dp),
            ) {
                Text("Update", color = Color.White)
            }
        }
    }
}

internal class UpdateDialogFragment : DialogFragment() {
    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        val mode = arguments?.getString(ARG_MODE) ?: AppUpdateChannelConstants.DIALOG_MODE_STORE
        val composeView = ComposeView(requireContext()).apply {
            setContent {
                MaterialTheme {
                    Surface(
                        shape = RoundedCornerShape(16.dp),
                        color = Color.White,
                    ) {
                        UpdateDialogContent(
                            onSkipClick = { dismiss() },
                            onUpdateClick = {
                                dismiss()
                                if (mode == AppUpdateChannelConstants.DIALOG_MODE_RESTART) {
                                    restartProcess(requireContext())
                                } else {
                                    openPlayStore(requireContext())
                                }
                            },
                        )
                    }
                }
            }
        }

        return Dialog(requireContext()).apply {
            setContentView(composeView)
            setCancelable(false)
            setCanceledOnTouchOutside(false)
            window?.setBackgroundDrawable(android.graphics.Color.TRANSPARENT.toDrawable())
        }
    }

    companion object {
        private const val ARG_MODE = "mode"

        fun newInstance(mode: String): UpdateDialogFragment {
            return UpdateDialogFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_MODE, mode)
                }
            }
        }
    }
}
