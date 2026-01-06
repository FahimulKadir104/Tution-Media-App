const teacherOnly = (req, res, next) => {
  if (req.user.role !== 'TEACHER') {
    return res.status(403).json({ message: 'Access denied. Teacher role required.' });
  }
  next();
};

module.exports = teacherOnly;