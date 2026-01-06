const studentOnly = (req, res, next) => {
  if (req.user.role !== 'STUDENT') {
    return res.status(403).json({ message: 'Access denied. Student role required.' });
  }
  next();
};

module.exports = studentOnly;