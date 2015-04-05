import com.twitter.finagle.{Http, Service}
import com.twitter.util.{Await, Future}
import com.twitter.finagle.http.Response
import java.net.InetSocketAddress
import org.jboss.netty.handler.codec.http._
import util.Properties

object Web {
  def main(args: Array[String]) {
    val port = Properties.envOrElse("PORT", "8080").toInt
    println("Starting on port:"+port)

    val server = Http.serve(":" + port, new Hello)
    Await.ready(server)
  }
}

class Hello extends Service[HttpRequest, HttpResponse] {
  def apply(req: HttpRequest): Future[HttpResponse] = {
    val response = Response()
    response.setStatusCode(200)
    response.setContentString("scala\n")
    Future(response)
  }
}
