import unittest

from django.test import Client


class GreetingTestCase(unittest.TestCase):

    def setUp(self):
        self.client = Client()

    def test_powered_by_deis(self):
        """This app must be powered by Deis"""
        resp = self.client.get('/')
        self.assertEqual(resp.content, 'Powered by Deis')
