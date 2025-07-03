import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class NavItemEntity extends Equatable {
  final String id;
  final String title;
  final String route;
  final IconData icon;
  final bool isActive;
  final int order;

  const NavItemEntity({
    required this.id,
    required this.title,
    required this.route,
    required this.icon,
    this.isActive = true,
    required this.order,
  });

  @override
  List<Object> get props => [id, title, route, icon, isActive, order];
}