import delete
import unittest


class TestDelete(unittest.TestCase):
    def setUp(self):
        print "setup"
        self.sess = delete.sessions()

    def test_list_servers_without_console(self):
        """ test method of list_servers_without_console """
        actual = delete.list_servers_without_console(self.sess)
        if actual:
            for a in actual:
                expected = "console"
                self.assertNotEqual(expected, a.name)
        else:
            expected = []
            self.assertEqual(expected, actual)

    def tearDown(self):
        print "tearDown"
        del self.sess
