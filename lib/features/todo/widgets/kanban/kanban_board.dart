import 'package:flutter/material.dart';
import '../../../../data/models/todo_model.dart';
import 'kanban_column.dart';

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: TodoStatus.values
                  .map(
                    (s) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: s == TodoStatus.todo ? 0 : 14,
                        ),
                        child: KanbanColumn(status: s),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          children: TodoStatus.values
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: constraints.maxWidth * 0.82,
                    child: KanbanColumn(status: s),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
