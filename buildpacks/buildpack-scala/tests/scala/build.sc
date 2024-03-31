import mill._
import $ivy.`com.lihaoyi::mill-contrib-playlib:`,  mill.playlib._

object scalagettingstarted extends PlayModule with SingleModule {

  def scalaVersion = "2.13.10"
  def playVersion = "2.8.19"
  def twirlVersion = "1.5.1"

}
