.. highlight:: lua

Geometry
========

This module contains classes for different types of indexed geomery. These
classes manage bgfx buffers.

.. function:: format_exception(etype, value, tb[, limit=None])

  Format the exception with a traceback.

  :param etype: exception type
  :param value: exception value
  :param tb: traceback object
  :param limit: maximum number of stack frames to show
  :type limit: integer or None
  :rtype: list of strings