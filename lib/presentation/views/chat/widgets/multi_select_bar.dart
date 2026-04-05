import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:inum/domain/models/chat/message_model.dart";
import "package:inum/presentation/design_system/colors.dart";

/// State holder for multi-select mode in chat.
class MultiSelectState {
  final Set<String> selectedIds;
  final bool isActive;

  const MultiSelectState({
    this.selectedIds = const {},
    this.isActive = false,
  });

  MultiSelectState copyWith({
    Set<String>? selectedIds,
    bool? isActive,
  }) {
    return MultiSelectState(
      selectedIds: selectedIds ?? this.selectedIds,
      isActive: isActive ?? this.isActive,
    );
  }

  int get count => selectedIds.length;
  bool isSelected(String id) => selectedIds.contains(id);
}

/// Floating action bar shown at the bottom during multi-select mode.
class MultiSelectActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCopy;
  final VoidCallback onForward;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final bool canDelete;

  const MultiSelectActionBar({
    super.key,
    required this.selectedCount,
    required this.onCopy,
    required this.onForward,
    required this.onDelete,
    required this.onCancel,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: selectedCount > 0 ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              "$selectedCount selected",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: inumPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 22),
              tooltip: "Copy",
              color: inumPrimary,
              onPressed: onCopy,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.forward, size: 22),
              tooltip: "Forward",
              color: inumPrimary,
              onPressed: onForward,
            ),
            if (canDelete) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 22),
                tooltip: "Delete",
                color: errorColor,
                onPressed: onDelete,
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 22),
              tooltip: "Cancel",
              color: customGreyColor600,
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkbox overlay for a message in selection mode.
class MessageSelectCheckbox extends StatelessWidget {
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;

  const MessageSelectCheckbox({
    super.key,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: isSelectionMode
          ? GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? inumPrimary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? inumPrimary : customGreyColor400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Combine selected message texts for clipboard copy.
String combineSelectedMessages(
    List<MessageModel> messages, Set<String> selectedIds) {
  final selected =
      messages.where((m) => selectedIds.contains(m.id)).toList();
  // Sort by creation date
  selected.sort((a, b) => a.createAt.compareTo(b.createAt));
  return selected.map((m) => m.message).join("\n");
}
