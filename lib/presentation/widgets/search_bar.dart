import 'package:flutter/material.dart';

/// Reusable search bar component
class SearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const SearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    required this.isDark,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF137FEC).withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: widget.isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                    ),
                    prefixIcon: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 2 * 3.14159,
                          child: Icon(
                            Icons.search,
                            color: widget.isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                          ),
                        );
                      },
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: widget.isDark ? const Color(0xFF8E8E93) : const Color(0xFF64748B),
                                  ),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {
                                      _query = '';
                                    });
                                    widget.onChanged('');
                                  },
                                ),
                              );
                            },
                          )
                        : null,
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: widget.isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
                  ),
                  onChanged: (query) {
                    setState(() {
                      _query = query;
                    });
                    widget.onChanged(query);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
