package com.overdrive.app.ui.fragment

import android.app.AlertDialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.overdrive.app.ui.adapter.DaemonAdapter
import com.overdrive.app.ui.viewmodel.DaemonsViewModel
import com.overdrive.app.ui.model.DaemonType
import com.overdrive.app.ui.model.DaemonState
import com.overdrive.app.R

/**
 * Fragment for managing background daemons.
 */
class DaemonsFragment : Fragment() {
    
    private val daemonsViewModel: DaemonsViewModel by activityViewModels()
    
    private lateinit var recyclerDaemons: RecyclerView
    private lateinit var daemonAdapter: DaemonAdapter
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_daemons, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        initViews(view)
        setupRecyclerView()
        observeViewModel()
        
        // Check Zrok token status on view creation
        checkZrokTokenStatus()
    }
    
    private fun initViews(view: View) {
        recyclerDaemons = view.findViewById(R.id.recyclerDaemons)
    }
    
    private fun setupRecyclerView() {
        daemonAdapter = DaemonAdapter(
            onToggle = { type, enabled -> onDaemonToggled(type, enabled) },
            onConfigureClick = { type -> onDaemonConfigureClicked(type) }
        )
        
        recyclerDaemons.apply {
            layoutManager = LinearLayoutManager(context)
            adapter = daemonAdapter
        }
    }
    
    private fun observeViewModel() {
        daemonsViewModel.daemonStates.observe(viewLifecycleOwner) { states ->
            // Convert map to list sorted by daemon type ordinal
            val sortedList = states.values.sortedBy { it.type.ordinal }
            daemonAdapter.submitList(sortedList)
        }
    }
    
    /**
     * Check if Zrok token is configured and update state accordingly.
     */
    private fun checkZrokTokenStatus() {
        daemonsViewModel.zrokController.hasEnableToken { hasToken ->
            activity?.runOnUiThread {
                if (!hasToken) {
                    // Update Zrok state to show configuration needed
                    daemonsViewModel.updateZrokNeedsConfig("No token configured. Tap to set up.")
                }
            }
        }
    }
    
    private fun onDaemonToggled(type: DaemonType, enabled: Boolean) {
        // Save preference for optional daemons (so they auto-start on next app launch if enabled)
        daemonsViewModel.daemonStartupManager?.onDaemonToggled(type, enabled)
        
        if (enabled) {
            daemonsViewModel.startDaemon(type)
        } else {
            daemonsViewModel.stopDaemon(type)
        }
    }
    
    private fun onDaemonConfigureClicked(type: DaemonType) {
        when (type) {
            DaemonType.ZROK_TUNNEL -> showZrokTokenDialog()
            else -> {
                // Other daemons don't need configuration yet
                Toast.makeText(context, "No configuration needed for ${type.displayName}", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    /**
     * Show dialog to configure Zrok enable token.
     */
    private fun showZrokTokenDialog() {
        val context = context ?: return
        
        // First get current token to show in dialog
        daemonsViewModel.zrokController.getEnableToken { currentToken ->
            activity?.runOnUiThread {
                val dialogView = LayoutInflater.from(context).inflate(R.layout.dialog_zrok_token, null)
                val editToken = dialogView.findViewById<EditText>(R.id.editZrokToken)
                
                // Pre-fill with current token if exists
                currentToken?.let { editToken.setText(it) }
                
                AlertDialog.Builder(context)
                    .setTitle("🌐 Zrok Tunnel Token")
                    .setMessage("Enter your Zrok enable token.\nGet one at: zrok.io")
                    .setView(dialogView)
                    .setPositiveButton("Save") { _, _ ->
                        val token = editToken.text.toString().trim()
                        if (token.isNotEmpty()) {
                            saveZrokToken(token)
                        } else {
                            Toast.makeText(context, "Token cannot be empty", Toast.LENGTH_SHORT).show()
                        }
                    }
                    .setNegativeButton("Cancel", null)
                    .setNeutralButton("Delete") { _, _ ->
                        deleteZrokToken()
                    }
                    .show()
            }
        }
    }
    
    private fun saveZrokToken(token: String) {
        daemonsViewModel.zrokController.saveEnableToken(token) { success ->
            activity?.runOnUiThread {
                if (success) {
                    Toast.makeText(context, "✅ Token saved", Toast.LENGTH_SHORT).show()
                    // Refresh Zrok status
                    daemonsViewModel.refreshDaemonStatus(DaemonType.ZROK_TUNNEL)
                } else {
                    Toast.makeText(context, "❌ Failed to save token", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
    
    private fun deleteZrokToken() {
        daemonsViewModel.zrokController.deleteEnableToken { success ->
            activity?.runOnUiThread {
                if (success) {
                    Toast.makeText(context, "Token deleted", Toast.LENGTH_SHORT).show()
                    // Update state to show configuration needed
                    daemonsViewModel.updateZrokNeedsConfig("No token configured. Tap to set up.")
                } else {
                    Toast.makeText(context, "❌ Failed to delete token", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
}
